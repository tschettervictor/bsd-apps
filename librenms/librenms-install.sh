#!/bin/sh
# Install LibreNMS

APP_NAME="LibreNMS"
ADMIN_PASSWORD="$(openssl rand -base64 12)"
DB_TYPE="MariaDB"
DB_NAME="librenms"
DB_USER="librenms"
DB_ROOT_PASSWORD="$(openssl rand -base64 15)"
DB_PASSWORD="$(openssl rand -base64 15)"
MARIADB_VERSION="123"
NO_CERT=0
SELFSIGNED_CERT=0
STANDALONE_CERT=0
DNS_CERT=0
DNS_PLUGIN=""
DNS_TOKEN=""
CERT_EMAIL=""
HOST_NAME=""
TIME_ZONE=""

# Check for Root Privileges
if ! [ "$(id -u)" = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Variable Checks
if [ -z "${TIME_ZONE}" ]; then
  echo 'Configuration error: TIME_ZONE must be set'
  exit 1
fi
if [ -z "${HOST_NAME}" ]; then
  echo 'Configuration error: HOST_NAME must be set'
  exit 1
fi
if [ "${STANDALONE_CERT}" -eq 0 ] && [ "${DNS_CERT}" -eq 0 ] && [ "${NO_CERT}" -eq 0 ] && [ "${SELFSIGNED_CERT}" -eq 0 ]; then
  echo 'Configuration error: Either STANDALONE_CERT, DNS_CERT, NO_CERT,'
  echo 'or SELFSIGNED_CERT must be set to 1.'
  exit 1
fi
if [ "${STANDALONE_CERT}" -eq 1 ] && [ "${DNS_CERT}" -eq 1 ] ; then
  echo 'Configuration error: Only one of STANDALONE_CERT and DNS_CERT'
  echo 'may be set to 1.'
  exit 1
fi
if [ "${DNS_CERT}" -eq 1 ] && [ -z "${DNS_PLUGIN}" ] ; then
  echo "DNS_PLUGIN must be set to a supported DNS provider."
  echo "See https://caddyserver.com/download for available plugins."
  echo "Use only the last part of the name.  E.g., for"
  echo "\"github.com/caddy-dns/cloudflare\", enter \"coudflare\"."
  exit 1
fi
if [ "${DNS_CERT}" -eq 1 ] && [ "${CERT_EMAIL}" = "" ] ; then
  echo "CERT_EMAIL must be set when using Let's Encrypt certs."
  exit 1
fi
if [ "${STANDALONE_CERT}" -eq 1 ] && [ "${CERT_EMAIL}" = "" ] ; then
  echo "CERT_EMAIL must be set when using Let's Encrypt certs."
  exit 1
fi

# Check for Reinstall
if [ "$(ls -A "/var/db/mysql/${DB_NAME}" 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} database detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Packages
pkg install -y \
go \
librenms \
mariadb"${MARIADB_VERSION}"-client \
mariadb"${MARIADB_VERSION}"-server \
python3

# Directories/Files
mkdir -p /var/db/mysql
chown -R 88:88 /var/db/mysql
mkdir -p /usr/local/www/librenms/config.d
touch /usr/local/www/librenms/config.d/.env
touch /usr/local/www/librenms/config.d/config.php
ln -sf /usr/local/www/librenms/config.d/.env /usr/local/www/librenms/.env
ln -sf /usr/local/www/librenms/config.d/config.php /usr/local/www/librenms/config.php
chown -R www:www /usr/local/www/librenms
chmod 600 /usr/local/www/librenms/config.d/.env
mkdir -p /var/db/librenms/rrd
chown -R www:www /var/db/librenms
chmod 775 /var/db/librenms/rrd

# Database
sysrc mysql_enable="YES"
fetch -o /usr/local/etc/mysql/conf.d/librenms.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/includes/librenms.cnf
service mysql-server start
if [ "${REINSTALL}" = "true" ]; then
	echo "You did a reinstall, but database passwords will still be changed."
 	echo "New passwords will still be saved in the root directory."
 	mysql -u root -e "SET PASSWORD FOR '${DB_USER}'@localhost = PASSWORD('${DB_PASSWORD}');"
  	sed -i '' "s|.*DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|g" /usr/local/www/librenms/config.d/.env
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
fi
service mysql-server restart

# PHP
sysrc php_fpm_enable="YES"
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
sed -i '' "s|^.*date.timezone = .*|date.timezone = ${TIME_ZONE}|" /usr/local/etc/php.ini
sed -i '' "s|^.*listen = .*|listen = 127.0.0.1:9000|" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s|^.*listen.owner = .*|listen.owner = www|" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s|^.*listen.group = .*|listen.group = www|" /usr/local/etc/php-fpm.d/www.conf
sed -i '' "s|^.*listen.mode = .*|listen.mode = 0660|" /usr/local/etc/php-fpm.d/www.conf
service php_fpm start

# Caddy
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
cp /root/go/bin/xcaddy /usr/local/bin/xcaddy
if [ "${DNS_CERT}" -eq 1 ]; then
	xcaddy build --output /usr/local/bin/caddy --with github.com/caddy-dns/"${DNS_PLUGIN}"
else
	xcaddy build --output /usr/local/bin/caddy
fi
if [ "${SELFSIGNED_CERT}" -eq 1 ]; then
	mkdir -p /usr/local/etc/pki/tls/private
  	mkdir -p /usr/local/etc/pki/tls/certs
  	openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=${HOST_NAME}" -keyout /tmp/privkey.pem -out /tmp/fullchain.pem
  	cp /tmp/privkey.pem /usr/local/etc/pki/tls/private/privkey.pem
  	cp /tmp/fullchain.pem /usr/local/etc/pki/tls/certs/fullchain.pem
fi
if [ "${STANDALONE_CERT}" -eq 1 ] || [ "${DNS_CERT}" -eq 1 ]; then
	fetch -o /root/ https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/includes/remove-staging.sh
  	chmod +x /root/remove-staging.sh
fi
if [ "${NO_CERT}" -eq 1 ]; then
	echo "Fetching Caddyfile for no SSL"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/includes/Caddyfile-nossl
elif [ "${SELFSIGNED_CERT}" -eq 1 ]; then
	echo "Fetching Caddyfile for self-signed cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/includes/Caddyfile-selfsigned
elif [ "${DNS_CERT}" -eq 1 ]; then
  	echo "Fetching Caddyfile for Let's Encrypt DNS cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/includes/Caddyfile-dns
else
  	echo "Fetching Caddyfile for Let's Encrypt cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/includes/Caddyfile
fi
fetch -o /usr/local/etc/rc.d/caddy https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/librenms/includes/caddy
chmod +x /usr/local/etc/rc.d/caddy
sed -i '' "s/yourhostnamehere/${HOST_NAME}/" /usr/local/www/Caddyfile
sed -i '' "s/dns_plugin/${DNS_PLUGIN}/" /usr/local/www/Caddyfile
sed -i '' "s/api_token/${DNS_TOKEN}/" /usr/local/www/Caddyfile
sed -i '' "s/youremailhere/${CERT_EMAIL}/" /usr/local/www/Caddyfile
sysrc caddy_enable="YES"
sysrc caddy_config="/usr/local/www/Caddyfile"
service caddy start

# LibreNMS
sysrc librenms_enable="YES"
if [ "${REINSTALL}" = "true" ]; then
    sed -i '' "s|^DB_PASSWORD.*|DB_PASSWORD=${DB_PASSWORD}|" /usr/local/www/librenms/config.d/.env
else
    cp -f /usr/local/www/librenms/config.php.default /usr/local/www/librenms/config.d/config.php
    cp -f /usr/local/www/librenms/.env.example /usr/local/www/librenms/config.d/.env
    sed -i '' "s|^DB_DATABASE.*|DB_DATABASE=${DB_NAME}|" /usr/local/www/librenms/config.d/.env
    sed -i '' "s|^DB_USERNAME.*|DB_USERNAME=${DB_USER}|" /usr/local/www/librenms/config.d/.env
    sed -i '' "s|^DB_PASSWORD.*|DB_PASSWORD=${DB_PASSWORD}|" /usr/local/www/librenms/config.d/.env
    sed -i '' "s|^DB_HOST.*|DB_HOST=127.0.0.1|" /usr/local/www/librenms/config.d/.env
    su -m www -c 'cd /usr/local/www/librenms && lnms config:clear'
    su -m www -c 'cd /usr/local/www/librenms && lnms config:cache'
    su -m www -c 'cd /usr/local/www/librenms && php artisan -n key:generate --force'
    su -m www -c 'cd /usr/local/www/librenms && lnms config:clear'
    su -m www -c 'cd /usr/local/www/librenms && lnms config:cache'
    su -m www -c 'cd /usr/local/www/librenms && lnms migrate -n --force --seed'
    su -m www -c 'cd /usr/local/www/librenms && lnms config:clear'
    su -m www -c 'cd /usr/local/www/librenms && lnms config:cache'
    su -m www -c "cd /usr/local/www/librenms && lnms user:add -n --password=${ADMIN_PASSWORD} --role=admin -- admin"
fi
if [ "${NO_CERT}" -eq 1 ]; then
    sed -i '' "s|^SESSION_SECURE_COOKIE=.*|SESSION_SECURE_COOKIE=false|" /usr/local/www/librenms/config.d/.env
else
    sed -i '' "s|^.*APP_URL=.*|APP_URL=https://${HOST_NAME}|" /usr/local/www/librenms/config.d/.env
    if grep -Eq "^ASSET_URL=" "/usr/local/www/librenms/config.d/.env"; then
        sed -i '' "s|^.*ASSET_URL=.*|ASSET_URL=https://${HOST_NAME}|" /usr/local/www/librenms/config.d/.env
    else
        echo "ASSET_URL=https://${HOST_NAME}" >> /usr/local/www/librenms/config.d/.env
    fi
fi
su -m www -c 'cd /usr/local/www/librenms && lnms config:clear'
su -m www -c 'cd /usr/local/www/librenms && lnms config:cache'
service librenms start

# Save Passwords
echo "${DB_TYPE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/"${APP_NAME}"-Info.txt
echo "${APP_NAME} database user is ${DB_USER} and password is ${DB_PASSWORD}" >> /root/"${APP_NAME}"-Info.txt
if [ "${REINSTALL}" != "true" ]; then
    echo "${APP_NAME} username is admin and password is ${ADMIN_PASSWORD}" >> /root/"${APP_NAME}"-Info.txt
fi

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 80."
echo "---------------"
echo "Database Information"
echo "${DB_TYPE} Username: root"
echo "${DB_TYPE} Password: ${DB_ROOT_PASSWORD}"
echo "${APP_NAME} DB User: ${DB_USER}"
echo "${APP_NAME} DB Password: ${DB_PASSWORD}"
echo "---------------"
if [ "${REINSTALL}" = "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "---------------"
else
	echo "User Information"
	echo "Default ${APP_NAME} user is admin"
	echo "Default ${APP_NAME} password is ${ADMIN_PASSWORD}"
	echo "---------------"
fi
echo "All passwords are saved in /root/${APP_NAME}-Info.txt"
echo "---------------"
if [ "${STANDALONE_CERT}" -eq 1 ] || [ "${DNS_CERT}" -eq 1 ]; then
  	echo "You have obtained your Let's Encrypt certificate using the staging server."
  	echo "This certificate will not be trusted by your browser and will cause SSL errors"
  	echo "when you connect.  Once you've verified that everything else is working"
  	echo "correctly, you should issue a trusted certificate.  To do this, run:"
  	echo "/root/remove-staging.sh"
	echo "---------------"
elif [ "${SELFSIGNED_CERT}" -eq 1 ]; then
  	echo "You have chosen to create a self-signed TLS certificate for your installation."
  	echo "installation.  This certificate will not be trusted by your browser and"
  	echo "will cause SSL errors when you connect.  If you wish to replace this certificate"
  	echo "with one obtained elsewhere, the private key is located at:"
  	echo "/usr/local/etc/pki/tls/private/privkey.pem"
 	echo "The full chain (server + intermediate certificates together) is at:"
  	echo "/usr/local/etc/pki/tls/certs/fullchain.pem"
	echo "---------------"
fi
if [ "${NO_CERT}" -eq 1 ]; then
	echo "Using your web browser, go to http://${HOST_NAME} to log in"
 	echo "---------------"
else
	echo "Using your web browser, go to https://${HOST_NAME} to log in"
 	echo "---------------"
fi
