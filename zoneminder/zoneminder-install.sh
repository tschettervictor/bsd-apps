#!/bin/sh
# Install Zoneminder

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

APP_NAME="zoneminder"
MYSQL_VERSION="80"
DATABASE="MySQL"
DB_ROOT_PASSWORD=$(openssl rand -base64 15)
DB_NAME="zm"
ZM_USER="zmuser"
ZM_PASS=$(openssl rand -base64 15)

# Install Packages
pkg install -y zoneminder fcgiwrap mysql${MYSQL_VERSION}-server openssl nginx

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

# Start services (zoneminder will be started later)
service mysql-server start
service nginx start
service php-fpm start
service fcgiwrap start 

# Create and Configure Database
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';CREATE DATABASE ${DB_NAME};CREATE USER '${ZM_USER}'@'localhost' IDENTIFIED BY '${ZM_PASS}';GRANT SELECT,INSERT,UPDATE,DELETE ON ${DB_NAME}.* TO '${ZM_USER}'@'localhost';FLUSH PRIVILEGES;";
mysql -u root --password='${DB_ROOT_PASSWORD}' '${DB_NAME}' < /usr/local/share/zoneminder/db/zm_create.sql
echo "ZM_DB_NAME='${DB_NAME}'" > /usr/local/etc/zoneminder/zm-truenas.conf
echo "ZM_DB_USER='${ZM_USER}'" >> /usr/local/etc/zoneminder/zm-truenas.conf
echo "ZM_DB_PASS='${ZM_PASS}'" >> /usr/local/etc/zoneminder/zm-truenas.conf

# Fetch Config Files
fetch -o /usr/local/etc/php.ini https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/php.ini
fetch -o /usr/local/etc/php-fpm.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/php-fpm.conf
fetch -o /usr/local/etc/php-fpm.d/zoneminder.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/zoneminder.conf.php-fpm
fetch -o /usr/local/etc/nginx/nginx.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/nginx.conf
fetch -o /usr/local/etc/nginx/conf.d/zoneminder.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/zoneminder.conf.nginx.ssl
fetch -o /usr/local/etc/mysql/conf.d/zoneminder.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zoneminder/includes/my.cnf

# Restart Services and start Zoneminder
service mysql-server restart
service fcgiwrap restart 
service php-fpm restart
service nginx restart
service zoneminder start

# Save passwords for later reference
echo "${DATABASE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}_passwords.txt
echo "Zoneminder database user is ${ZM_USER} and password is ${ZM_PASS}" >> /root/${APP_NAME}_passwords.txt


echo "---------------"
echo "Installation complete."
echo "---------------"
echo "Database Information"
echo "MySQL Username: root"
echo "MySQL Password: ${DB_ROOT_PASSWORD}"
echo "Zoneminder DB User: ${ZM_USER}"
echo "Zoneminder DB Password: ${ZM_PASS}"
echo "---------------"
echo "All passwords are saved in /root/${APP_NAME}_passwords.txt"
