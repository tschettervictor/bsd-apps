#!/bin/sh
# Install Wordpress

APP_NAME="Wordpress"
DB_TYPE="MariaDB"
DB_NAME="wordpress"
DB_USER="wordpress"
DB_ROOT_PASSWORD=$(openssl rand -base64 16)
DB_PASSWORD=$(openssl rand -base64 16)
NO_CERT=0
SELFSIGNED_CERT=0
STANDALONE_CERT=0
DNS_CERT=0
DNS_PLUGIN=""
DNS_TOKEN=""
CERT_EMAIL=""
COUNTRY_CODE=""
HOST_NAME=""
TIME_ZONE=""
PHP_VERSION="83"
MARIADB_VERSION="106"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Variable Checks
if [ -z "${COUNTRY_CODE}" ]; then
  echo 'Configuration error: COUNTRY_CODE must be set'
  exit 1
fi
if [ -z "${TIME_ZONE}" ]; then
  echo 'Configuration error: TIME_ZONE must be set'
  exit 1
fi
if [ -z "${HOST_NAME}" ]; then
  echo 'Configuration error: HOST_NAME must be set'
  exit 1
fi
if [ $STANDALONE_CERT -eq 0 ] && [ $DNS_CERT -eq 0 ] && [ $NO_CERT -eq 0 ] && [ $SELFSIGNED_CERT -eq 0 ]; then
  echo 'Configuration error: Either STANDALONE_CERT, DNS_CERT, NO_CERT,'
  echo 'or SELFSIGNED_CERT must be set to 1.'
  exit 1
fi
if [ $STANDALONE_CERT -eq 1 ] && [ $DNS_CERT -eq 1 ] ; then
  echo 'Configuration error: Only one of STANDALONE_CERT and DNS_CERT'
  echo 'may be set to 1.'
  exit 1
fi
if [ $DNS_CERT -eq 1 ] && [ -z "${DNS_PLUGIN}" ] ; then
  echo "DNS_PLUGIN must be set to a supported DNS provider."
  echo "See https://caddyserver.com/download for available plugins."
  echo "Use only the last part of the name.  E.g., for"
  echo "\"github.com/caddy-dns/cloudflare\", enter \"coudflare\"."
  exit 1
fi
if [ $DNS_CERT -eq 1 ] && [ "${CERT_EMAIL}" = "" ] ; then
  echo "CERT_EMAIL must be set when using Let's Encrypt certs."
  exit 1
fi
if [ $STANDALONE_CERT -eq 1 ] && [ "${CERT_EMAIL}" = "" ] ; then
  echo "CERT_EMAIL must be set when using Let's Encrypt certs."
  exit 1
fi

# Package Installation
pkg install -y go redis mariadb${MARIADB_VERSION}-server mariadb${MARIADB_VERSION}-client php${PHP_VERSION} php${PHP_VERSION}-curl php${PHP_VERSION}-dom php${PHP_VERSION}-fileinfo php${PHP_VERSION}-exif php${PHP_VERSION}-mbstring php${PHP_VERSION}-extensions php${PHP_VERSION}-mysqli php${PHP_VERSION}-pecl-libsodium php${PHP_VERSION}-zip php${PHP_VERSION}-filter php${PHP_VERSION}-gd php${PHP_VERSION}-iconv php${PHP_VERSION}-xml php${PHP_VERSION}-simplexml php${PHP_VERSION}-xmlreader php${PHP_VERSION}-zlib php${PHP_VERSION}-ftp php${PHP_VERSION}-pecl-ssh2 php${PHP_VERSION}-sockets php${PHP_VERSION}-ctype php${PHP_VERSION}-session php${PHP_VERSION}-xmlwriter php${PHP_VERSION}-pecl-redis php${PHP_VERSION}-pecl-imagick php${PHP_VERSION}-pecl-mcrypt php${PHP_VERSION}-bcmath

# Create Directories
mkdir -p /usr/local/www
mkdir -p /usr/local/etc/rc.d

# Create and Configure Database
sysrc mysql_enable=YES
service mysql-server start
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
fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/wordpress/includes/my.cnf
sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf

# Wordpress Setup
fetch -o /tmp https://wordpress.org/latest.tar.gz
tar xjf /tmp/latest.tar.gz -C /usr/local/www/
cp /usr/local/www/wordpress/wp-config-sample.php /usr/local/www/wordpress/wp-config.php
sed -i '' "s/database_name_here/wordpress/" /usr/local/www/wordpress/wp-config.php
sed -i '' "s/username_here/wordpress/" /usr/local/www/wordpress/wp-config.php
sed -i '' "s|password_here|${DB_PASSWORD}|" /usr/local/www/wordpress/wp-config.php
sed -i '' "s/localhost/127.0.0.1/" /usr/local/www/wordpress/wp-config.php
sed -i '' "s|define( 'AUTH_KEY',.*|define( 'AUTH_KEY',         '$(openssl rand -base64 64 | tr -d '\n' | sed 's/[&/\]/\\&/g')' );|" /usr/local/www/wordpress/wp-config.php
sed -i '' "s|define( 'SECURE_AUTH_KEY',.*|define( 'SECURE_AUTH_KEY',  '$(openssl rand -base64 64 | tr -d '\n' | sed 's/[&/\]/\\&/g')' );|" /usr/local/www/wordpress/wp-config.php
sed -i '' "s|define( 'LOGGED_IN_KEY',.*|define( 'LOGGED_IN_KEY',    '$(openssl rand -base64 64 | tr -d '\n' | sed 's/[&/\]/\\&/g')' );|" /usr/local/www/wordpress/wp-config.php
sed -i '' "s|define( 'NONCE_KEY',.*|define( 'NONCE_KEY',        '$(openssl rand -base64 64 | tr -d '\n' | sed 's/[&/\]/\\&/g')' );|" /usr/local/www/wordpress/wp-config.php
sed -i '' "s|define( 'AUTH_SALT',.*|define( 'AUTH_SALT',        '$(openssl rand -base64 64 | tr -d '\n' | sed 's/[&/\]/\\&/g')' );|" /usr/local/www/wordpress/wp-config.php
sed -i '' "s|define( 'SECURE_AUTH_SALT',.*|define( 'SECURE_AUTH_SALT', '$(openssl rand -base64 64 | tr -d '\n' | sed 's/[&/\]/\\&/g')' );|" /usr/local/www/wordpress/wp-config.php
sed -i '' "s|define( 'LOGGED_IN_SALT',.*|define( 'LOGGED_IN_SALT',   '$(openssl rand -base64 64 | tr -d '\n' | sed 's/[&/\]/\\&/g')' );|" /usr/local/www/wordpress/wp-config.php
sed -i '' "s|define( 'NONCE_SALT',.*|define( 'NONCE_SALT',       '$(openssl rand -base64 64 | tr -d '\n' | sed 's/[&/\]/\\&/g')' );|" /usr/local/www/wordpress/wp-config.php
chown -R www:www /usr/local/www

# PHP Setup
fetch -o /usr/local/etc/php.ini https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/wordpress/includes/php.ini
fetch -o /usr/local/etc/php-fpm.d/www.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/wordpress/includes/www.conf
sed -i '' "s|mytimezone|${TIME_ZONE}|" /usr/local/etc/php.ini
chown -R www:www /usr/local/etc/php.ini
sysrc php_fpm_enable="YES"
service php_fpm start

# Redis Setup
sysrc redis_enable="YES"
fetch -o /usr/local/etc/redis.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/redis/includes/redis.conf
pw usermod www -G redis
service redis start
chmod 777 /var/run/redis/redis.sock

# Caddy Setup
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
cp /root/go/bin/xcaddy /usr/local/bin/xcaddy
if [ ${DNS_CERT} -eq 1 ]; then
	xcaddy build --output /usr/local/bin/caddy --with github.com/caddy-dns/"${DNS_PLUGIN}"
else
	xcaddy build --output /usr/local/bin/caddy
fi
if [ $SELFSIGNED_CERT -eq 1 ]; then
	mkdir -p /usr/local/etc/pki/tls/private
  	mkdir -p /usr/local/etc/pki/tls/certs
  	openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=${HOST_NAME}" -keyout /tmp/privkey.pem -out /tmp/fullchain.pem
  	cp /tmp/privkey.pem /usr/local/etc/pki/tls/private/privkey.pem
  	cp /tmp/fullchain.pem /usr/local/etc/pki/tls/certs/fullchain.pem
fi
if [ $STANDALONE_CERT -eq 1 ] || [ $DNS_CERT -eq 1 ]; then
	fetch -o /root/ https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/wordpress/includes/remove-staging.sh
  	chmod +x /root/remove-staging.sh
fi
if [ $NO_CERT -eq 1 ]; then
	echo "Fetching Caddyfile for no SSL"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/wordpress/includes/Caddyfile-nossl
elif [ $SELFSIGNED_CERT -eq 1 ]; then
	echo "Fetching Caddyfile for self-signed cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/wordpress/includes/Caddyfile-selfsigned
elif [ $DNS_CERT -eq 1 ]; then
  	echo "Fetching Caddyfile for Let's Encrypt DNS cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/wordpress/includes/Caddyfile-dns
else
  	echo "Fetching Caddyfile for Let's Encrypt cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/wordpress/includes/Caddyfile
fi
fetch -o /usr/local/etc/rc.d/caddy https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/wordpress/includes/caddy
chmod +x /usr/local/etc/rc.d/caddy
sed -i '' "s/yourhostnamehere/${HOST_NAME}/" /usr/local/www/Caddyfile
sed -i '' "s/dns_plugin/${DNS_PLUGIN}/" /usr/local/www/Caddyfile
sed -i '' "s/api_token/${DNS_TOKEN}/" /usr/local/www/Caddyfile
sed -i '' "s/youremailhere/${CERT_EMAIL}/" /usr/local/www/Caddyfile
sysrc caddy_enable="YES"
sysrc caddy_config="/usr/local/www/Caddyfile"
service caddy start

# Restart Services
service php_fpm restart
service redis restart
service caddy restart

# Save Passwords
echo "${DB_TYPE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}-Info.txt
echo "${APP_NAME} database user is ${DB_USER} and password is ${DB_PASSWORD}" >> /root/${APP_NAME}-Info.txt
echo "${APP_NAME} default username and password are both guacadmin." >> /root/${APP_NAME}-Info.txt

# Done
echo "---------------"
echo "Installation complete!"
echo "---------------"
echo "Database Information"
echo "$DB_TYPE Username: root"
echo "$DB_TYPE Password: $DB_ROOT_PASSWORD"
echo "$APP_NAME DB User: $DB_USER"
echo "$APP_NAME DB Password: $DB_PASSWORD"
echo "--------------------"
if [ $STANDALONE_CERT -eq 1 ] || [ $DNS_CERT -eq 1 ]; then
  	echo "You have obtained your Let's Encrypt certificate using the staging server."
  	echo "This certificate will not be trusted by your browser and will cause SSL errors"
  	echo "when you connect.  Once you've verified that everything else is working"
  	echo "correctly, you should issue a trusted certificate.  To do this, run:"
  	echo "/root/remove-staging.sh"
  	echo "---------------"
elif [ $SELFSIGNED_CERT -eq 1 ]; then
  	echo "You have chosen to create a self-signed TLS certificate for your installation."
  	echo "installation.  This certificate will not be trusted by your browser and"
  	echo "will cause SSL errors when you connect.  If you wish to replace this certificate"
  	echo "with one obtained elsewhere, the private key is located at:"
  	echo "/usr/local/etc/pki/tls/private/privkey.pem"
  	echo "The full chain (server + intermediate certificates together) is at:"
  	echo "/usr/local/etc/pki/tls/certs/fullchain.pem"
  	echo "---------------"
fi
if [ $NO_CERT -eq 1 ]; then
	echo "Using your web browser, go to http://${HOST_NAME} to start setup."
 	echo "--------------------"
else
	echo "Using your web browser, go to https://${HOST_NAME} to start setup."
 	echo "--------------------"
fi
