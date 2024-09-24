#!/bin/sh
# Install Lychee

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

APP_NAME="Lychee"
MARIADB_VERSION="106"
PHP_VERSION="83"
DB_TYPE="MariaDB"
DB_NAME="lychee"
DB_USER="lychee"
DB_ROOT_PASSWORD=$(openssl rand -base64 15)
DB_PASSWORD=$(openssl rand -base64 15)

# Check for Reinstall
if [ "$(ls -A /var/db/mysql/"${DB_NAME}" 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} database detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Package Installation
pkg install -y caddy redis ffmpeg git-lite go mariadb${MARIADB_VERSION}-server p5-Image-ExifTool php${PHP_VERSION} php${PHP_VERSION}-bcmath php${PHP_VERSION}-ctype php${PHP_VERSION}-dom php${PHP_VERSION}-exif php${PHP_VERSION}-extensions php${PHP_VERSION}-fileinfo php${PHP_VERSION}-gd php${PHP_VERSION}-mbstring php${PHP_VERSION}-mysqli php${PHP_VERSION}-pdo_mysql php${PHP_VERSION}-pdo php${PHP_VERSION}-pecl-imagick php${PHP_VERSION}-pecl-redis php${PHP_VERSION}-simplexml php${PHP_VERSION}-tokenizer php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-zlib

# Create Directories
mkdir -p /usr/local/www

# Enable Services
sysrc php_fpm_enable=YES
sysrc caddy_enable=YES
sysrc caddy_config=/usr/local/www/Caddyfile
sysrc redis_enable=YES
sysrc mysql_enable=YES

# Create and Configure Database
service mysql-server start
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, but database passwords will still be changed."
 	echo "New passwords will still be saved in the root directory."
 	mysql -u root -e "SET PASSWORD FOR '${DB_USER}'@localhost = PASSWORD('${DB_PASSWORD}');"
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/lychee/includes/my.cnf
  sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
else
	if ! mysql -u root -e "CREATE DATABASE ${DB_NAME};"; then
		echo "Failed to create database, aborting..."
		exit 1
	fi
	mysql -u root -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@localhost IDENTIFIED BY '${DB_PASSWORD}';"
	mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
	mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
	mysql -u root -e "DROP DATABASE IF EXISTS test;"
	mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
	mysql -u root -e "FLUSH PRIVILEGES;"
	mysqladmin --user=root password "${DB_ROOT_PASSWORD}" reload
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/lychee/includes/my.cnf
	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
fi

# PHP Setup
fetch -o /usr/local/etc/php.ini https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/lychee/includes/php.ini
php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"
php -r "if (hash_file('sha384', '/tmp/composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('/tmp/composer-setup.php'); } echo PHP_EOL;"
php /tmp/composer-setup.php --install-dir /usr/local/bin --filename composer

# Install Lychee
fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/lychee/includes/Caddyfile
git clone https://github.com/LycheeOrg/Lychee /usr/local/www/lychee
cp /usr/local/www/lychee/.env.example /usr/local/www/lychee/.env
sh -c 'cd /usr/local/www/lychee/ && env COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --prefer-dist'
chown -R www:www /usr/local/www/Lychee
sed -i '' "s|DB_CONNECTION=sqlite|DB_CONNECTION=mysql|" /usr/local/www/lychee/.env
sed -i '' "s|DB_HOST=|DB_HOST=localhost|" /usr/local/www/lychee/.env
sed -i '' "s|#DB_DATABASE=|DB_DATABASE=${DB_NAME}|" /usr/local/www/lychee/.env
sed -i '' "s|DB_USERNAME=|DB_USERNAME=${DB_USER}|" /usr/local/www/lychee/.env
sed -i '' "s|DB_PASSWORD=|DB_PASSWORD=${DB_PASSWORD}|" /usr/local/www/lychee/.env

# Restart Services
service redis start
service php-fpm start
service caddy start
service mysql-server restart

# Save Passwords
echo "${DB_TYPE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}-Info.txt
echo "${APP_NAME} database user is ${DB_USER} and password is ${DB_PASSWORD}" >> /root/${APP_NAME}-Info.txt

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 80."
echo "---------------"
echo "Database Information"
echo "$DB_TYPE Username: root"
echo "$DB_TYPE Password: $DB_ROOT_PASSWORD"
echo "$APP_NAME DB User: $DB_USER"
echo "$APP_NAME DB Password: $DB_PASSWORD"
echo "---------------"
echo "All passwords are saved in /root/${APP_NAME}-Info.txt"
echo "---------------"
