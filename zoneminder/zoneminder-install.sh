#!/bin/sh
# Install Zoneminder

APP_NAME="ZoneMinder"
DB_TYPE="MySQL"
DB_NAME="zm"
DB_USER="zm"
DB_ROOT_PASSWORD=$(openssl rand -base64 15)
DB_PASS=$(openssl rand -base64 15)
MYSQL_VERSION="80"
PHP_VERSION="85"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y \
fcgiwrap \
mysql${MYSQL_VERSION}-server \
nginx \
openssl \
p5-DateTime \
zoneminder-php${PHP_VERSION}

# Create Directories
mkdir -p /usr/local/etc/mysql/conf.d
mkdir -p /usr/local/etc/nginx/conf.d
mkdir -p /usr/local/etc/php-fpm.d
mkdir -p /usr/local/etc/zoneminder
mkdir -p /usr/local/etc/ssl
mkdir -p /var/db/zoneminder/events
mkdir -p /var/db/zoneminder/images
mkdir -p /var/log/zm
chown www:www /var/log/zm
chmod g+rw,o+rw,+t /tmp

# Enable and Configure Services
sysrc nginx_enable="YES"
sysrc mysql_enable="YES"
sysrc fcgiwrap_enable="YES"
sysrc fcgiwrap_user="www"
sysrc fcgiwrap_socket_owner="www" 
sysrc fcgiwrap_flags="-c 4"
sysrc php_fpm_enable="YES"
sysrc zoneminder_enable="YES"

# Generat SSL Certificate for Nginx
openssl req -new -newkey rsa:2048 -days 366 -nodes -x509 -subj "/O=ZoneMinder Home/CN=*" -keyout /usr/local/etc/ssl/key.pem -out /usr/local/etc/ssl/cert.pem

# Start Services (zoneminder will be started later)
service mysql-server start
service nginx start
service php_fpm start
service fcgiwrap start 

# Create and Configure Database
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';"
mysql -u root --password=${DB_ROOT_PASSWORD} -e "CREATE DATABASE ${DB_NAME};"
mysql -u root --password=${DB_ROOT_PASSWORD} -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -u root --password=${DB_ROOT_PASSWORD} -e "GRANT SELECT,INSERT,UPDATE,ALTER,DELETE ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -u root --password=${DB_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"
if [ "${DB_NAME}" != "zm" ]; then
    sed 's/^CREATE DATABASE.*//g;s/USE `zm`/USE `'${DB_NAME}'`/g' < /usr/local/share/zoneminder/db/zm_create.sql | \
      mysql -u root --password=${DB_ROOT_PASSWORD} ${DB_NAME}
else
    mysql -u root --password=${DB_ROOT_PASSWORD} ${DB_NAME} < /usr/local/share/zoneminder/db/zm_create.sql
fi
echo "ZM_DB_NAME=${DB_NAME}" > /usr/local/etc/zoneminder/zm-truenas.conf
echo "ZM_DB_USER=${DB_USER}" >> /usr/local/etc/zoneminder/zm-truenas.conf
echo "ZM_DB_PASS=${DB_PASS}" >> /usr/local/etc/zoneminder/zm-truenas.conf

# Fetch Config Files
fetch -o /usr/local/etc/php.ini https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/php.ini
fetch -o /usr/local/etc/php-fpm.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/php-fpm.conf
fetch -o /usr/local/etc/php-fpm.d/zoneminder.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/zoneminder.conf.php-fpm
fetch -o /usr/local/etc/nginx/nginx.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/nginx.conf
fetch -o /usr/local/etc/nginx/conf.d/zoneminder.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/zoneminder.conf.nginx.ssl
fetch -o /usr/local/etc/mysql/conf.d/zoneminder.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/my.cnf

# Restart Services and Start Zoneminder
service mysql-server restart
service fcgiwrap restart 
service php_fpm restart
service nginx restart
service zoneminder start

# Save Passwords
echo "${DB_TYPE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}-Info.txt
echo "${APP_NAME} database user is ${DB_USER} and password is ${DB_PASS}" >> /root/${APP_NAME}-Info.txt

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 443"
echo "---------------"
echo "Database Information"
echo "${DB_TYPE} DB Name: ${DB_NAME}"
echo "${DB_TYPE} Username: root"
echo "${DB_TYPE} Password: ${DB_ROOT_PASSWORD}"
echo "${APP_NAME} DB User: ${DB_USER}"
echo "${APP_NAME} DB Password: ${DB_PASS}"
echo "---------------"
echo "All passwords are saved in /root/${APP_NAME}-Info.txt"
