#!/bin/sh
# Install Piwigo Gallery

APP_NAME="Piwigo"
DB_TYPE="MariaDB"
DB_NAME="piwigo"
DB_USER="piwigo"
DB_ROOT_PASSWORD=$(openssl rand -base64 15)
DB_PASSWORD=$(openssl rand -base64 15)
PHP_VERSION="83"
MARIADB_VERSION="106"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ "$(ls -A /var/db/mysql/"${DB_NAME}" 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} database detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Package installation
pkg install -y \
bzip2 \
caddy \
ffmpeg \
imagemagick7 \
mariadb${MARIADB_VERSION}-client \
mariadb${MARIADB_VERSION}-server \
mediainfo \
p5-Image-ExifTool \
php${PHP_VERSION} \
php${PHP_VERSION}-ctype \
php${PHP_VERSION}-dom \
php${PHP_VERSION}-exif \
php${PHP_VERSION}-filter \
php${PHP_VERSION}-gd \
php${PHP_VERSION}-iconv \
php${PHP_VERSION}-mbstring \
php${PHP_VERSION}-mysqli \
php${PHP_VERSION}-pdo \
php${PHP_VERSION}-pdo_mysql \
php${PHP_VERSION}-session \
php${PHP_VERSION}-simplexml \
php${PHP_VERSION}-sodium \
php${PHP_VERSION}-tokenizer \
php${PHP_VERSION}-xml \
php${PHP_VERSION}-zlib \
php${PHP_VERSION}-zip \
wget

# Create Directories
mkdir -p /var/db/mysql
chown -R 88:88 /var/db/mysql
mkdir -p /usr/local/www/piwigo/galleries
mkdir -p /usr/local/www/piwigo/upload
mkdir -p /usr/local/www/piwigo/local/config

# Create and Configure Database
sysrc mysql_enable=YES
service mysql-server start
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, but the ${DB_TYPE} root password AND ${APP_NAME} database password will be changed."
 	echo "New passwords will be saved in the root directory."
 	mysql -u root -e "SET PASSWORD FOR '${DB_USER}'@localhost = PASSWORD('${DB_PASSWORD}');"
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/piwigo/includes/my.cnf
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
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/piwigo/includes/my.cnf
	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
fi

# Install Piwigo
fetch -o /tmp "http://piwigo.org/download/dlcounter.php?code=latest"
mv "/tmp/dlcounter.php?code=latest" /tmp/piwigo.zip
unzip -n -d /usr/local/www /tmp/piwigo.zip
sh -c 'find /usr/local/www/ -type d -print0 | xargs -0 chmod 775'
sh -c 'find /usr/local/www/ -type f -print0 | xargs -0 chmod 644'
if [ "${REINSTALL}" == "true" ]; then
	sed -i '' -e "s|.*db_password.*|\$conf['db_password'] = '${DB_PASSWORD}';|g" /usr/local/www/piwigo/local/config/database.inc.php	
fi
chown -R www:www /usr/local/www

# Enable and Start Services
fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/piwigo/includes/Caddyfile-nossl
sysrc php_fpm_enable=YES
sysrc caddy_enable=YES
sysrc caddy_config=/usr/local/www/Caddyfile
service php_fpm start
service caddy start
service mysql-server restart

# Save Passwords
echo "${DB_TYPE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}-Info.txt
echo "${APP_NAME} database user is ${DB_USER} and password is ${DB_PASSWORD}" >> /root/${APP_NAME}-Info.txt

# Done
echo "---------------"
echo "Installation Complete."
echo "${APP_NAME} is running on port 80."
echo "---------------"
echo "Database Information"
echo "$DB_TYPE Username: root"
echo "$DB_TYPE Password: $DB_ROOT_PASSWORD"
echo "$APP_NAME DB User: $DB_USER"
echo "$APP_NAME DB Password: $DB_PASSWORD"
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall."
	echo "Please user your old credentials to log in."
        echo "---------------"
fi
echo "All passwords are saved in /root/${APP_NAME}-Info.txt"
echo "---------------"
