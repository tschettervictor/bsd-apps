#!/bin/sh
# Install LibreNMS

APP_NAME="LibreNMS"
DB_TYPE="MariaDB"
DB_NAME="librenms"
DB_USER="librenms"
DB_ROOT_PASSWORD=$(openssl rand -base64 15)
DB_PASSWORD=$(openssl rand -base64 15)
MARIADB_VERSION="123"

# Check for Root Privileges
if ! [ "$(id -u)" = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ "$(ls -A /var/db/mysql/"${DB_NAME}" 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} database detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Package Installation
pkg install -y \
caddy \
librenms \
mariadb"${MARIADB_VERSION}"-client \
mariadb"${MARIADB_VERSION}"-server

# Directories
mkdir -p /var/db/mysql
chown -R 88:88 /var/db/mysql
mkdir -p /var/db/librenms/rrd
chown -R www:www /var/db/librenms
chmod 775 /var/db/librenms/rrd

# Database
sysrc mysql_enable="YES"
service mysql-server start
if [ "${REINSTALL}" = "true" ]; then
	echo "You did a reinstall, but database passwords will still be changed."
 	echo "New passwords will still be saved in the root directory."
 	mysql -u root -e "SET PASSWORD FOR '${DB_USER}'@localhost = PASSWORD('${DB_PASSWORD}');"
  	sed -i '' "s|.*DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|g" /usr/local/www/librenms/.env
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/includes/my.cnf
  	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
else
	if ! mysql -u root -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"; then
		echo "Failed to create ${APP_NAME} database, aborting..."
		exit 1
	fi
	mysql -u root -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@localhost IDENTIFIED BY '${DB_PASSWORD}';"
	mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
	mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
	mysql -u root -e "DROP DATABASE IF EXISTS test;"
	mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
	mysql -u root -e "FLUSH PRIVILEGES;"
	mysqladmin --user=root password "${DB_ROOT_PASSWORD}" reload
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/includes/my.cnf
	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
    fetch -o /usr/local/etc/mysql/conf.d/librenms.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/includes/librenms.cnf
fi

# PHP
sysrc php_fpm_enable="YES"
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
sed -i '' "s|^.*date.timezone.*|date.timezone = ${TIME_ZONE}|" /usr/local/etc/php.ini
sed -i '' "s|^.*listen = .*|listen = 127.0.0.1:9000|" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s|^.*listen.owner = .*|listen.owner = www|" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s|^.*listen.group = .*|listen.group = www|" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s|^.*listen.mode = .*|listen.mode = 0660|" /usr/local/etc/php-fpm.d/www.conf
service php_fpm start

# Caddy
fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/includes/Caddyfile-nossl
sysrc caddy_enable=YES
sysrc caddy_config=/usr/local/www/Caddyfile
service caddy start

# LibreNMS Setup
cp /usr/local/www/librenms/config.php.default /usr/local/www/librenms/config.php
cp /usr/local/www/librenms/.env.example /usr/local/www/librenms/.env
sed -i '' "s|^DB_DATABASE.*|DB_DATABASE=${DB_NAME}|" /usr/local/www/librenms/.env
sed -i '' "s|^DB_USERNAME.*|DB_USERNAME=${DB_USER}|" /usr/local/www/librenms/.env
sed -i '' "s|^DB_PASSWORD.*|DB_PASSWORD=${DB_PASSWORD}|" /usr/local/www/librenms/.env
sed -i '' "s|^DB_HOST.*|DB_HOST=127.0.0.1|" /usr/local/www/librenms/.env
echo "INSTALL=true" >> /usr/local/www/librenms/.env
sh -c 'cd /usr/local/www/librenms/html && php artisan key:generate'
chmod 600 /usr/local/www/librenms/.env
sh -c 'cd /usr/local/www/html/ && lnms config:clear'
sh -c 'cd /usr/local/www/html/ && lnms config:cache'
sysrc librenms_enable="YES"
service librenms start

# Save Passwords
echo "${DB_TYPE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}-Info.txt
echo "${APP_NAME} database user is ${DB_USER} and password is ${DB_PASSWORD}" >> /root/${APP_NAME}-Info.txt
echo "${APP_NAME} default username and password are both guacadmin." >> /root/${APP_NAME}-Info.txt

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 8080."
echo "---------------"
echo "Database Information"
echo "$DB_TYPE Username: root"
echo "$DB_TYPE Password: $DB_ROOT_PASSWORD"
echo "$APP_NAME DB User: $DB_USER"
echo "$APP_NAME DB Password: $DB_PASSWORD"
echo "---------------"
if [ "${REINSTALL}" = "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "---------------"
else
	echo "Please visit http://IP/install to start setup."
    echo "You MUST remove 'INSTALL=true' from /usr/local/www/librenms/.env when setup is complete."
	echo "---------------"
fi
echo "All passwords are saved in /root/${APP_NAME}-Info.txt"
echo "---------------"
