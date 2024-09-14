#!/bin/sh
# Install Nextcloud

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

HOST_NAME=""
TIME_ZONE=""
STANDALONE_CERT=0
SELFSIGNED_CERT=0
DNS_CERT=0
NO_CERT=1
DNS_PLUGIN=""
CERT_EMAIL=""

APP_NAME="nextcloud"
DATABASE="mariadb"
DB_PATH="/var/db/mysql"
FILES_PATH="/mnt/files"
NEXTCLOUD_VERSION="29"
PHP_VERSION="83"
COUNTRY_CODE="CA"
MX_WINDOW="5"
ADMIN_PASSWORD=$(openssl rand -base64 12)
DB_ROOT_PASSWORD=$(openssl rand -base64 16)
DB_NAME="nextcloud"
DB_PASSWORD=$(openssl rand -base64 16)

# Sanity Checks
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

# Check for Reinstall
if [ "$(ls -A "${CONFIG_PATH}")" ]; then
	echo "Existing Nextcloud config detected... Checking Database compatibility for reinstall"
	if [ "$(ls -A "${DB_PATH}/${DB_NAME}")" ]; then
		echo "Database is compatible, continuing..."
		REINSTALL="true"
	else
		echo "ERROR: You can not reinstall without the previous database"
		echo "Please try again after removing your config files or using the same database used previously"
		exit 1
	fi
fi

# Package Installation
pkg install -y nano sudo vim redis gnupg bash go git ffmpeg perl5 p5-Locale-gettext help2man texinfo m4 autoconf openssl php${PHP_VERSION} php${PHP_VERSION}-ctype php${PHP_VERSION}-curl php${PHP_VERSION}-dom php${PHP_VERSION}-filter php${PHP_VERSION}-gd php${PHP_VERSION}-xml php${PHP_VERSION}-mbstring php${PHP_VERSION}-posix php${PHP_VERSION}-session php${PHP_VERSION}-simplexml php${PHP_VERSION}-xmlreader php${PHP_VERSION}-xmlwriter php${PHP_VERSION}-zip php${PHP_VERSION}-zlib php${PHP_VERSION}-fileinfo php${PHP_VERSION}-bz2 php${PHP_VERSION}-intl php${PHP_VERSION}-ldap php${PHP_VERSION}-pecl-smbclient php${PHP_VERSION}-ftp php${PHP_VERSION}-imap php${PHP_VERSION}-bcmath php${PHP_VERSION}-gmp php${PHP_VERSION}-exif php${PHP_VERSION}-pecl-APCu php${PHP_VERSION}-pecl-memcache php${PHP_VERSION}-pecl-redis php${PHP_VERSION}-pecl-imagick php${PHP_VERSION}-pcntl php${PHP_VERSION}-phar php${PHP_VERSION}-iconv php${PHP_VERSION}-sodium php${PHP_VERSION}-sysvsem php${PHP_VERSION}-xsl php${PHP_VERSION}-opcache

# Create Directories
if [ "${DATABASE}" = "mariadb" ]; then
  mkdir -p /var/db/mysql
elif [ "${DATABASE}" = "pgsql" ]; then
  mkdir -p /var/db/postgres
fi
mkdir -p /mnt/files
mkdir -p /usr/local/www/nextcloud/config
mkdir -p /usr/local/www/nextcloud/themes
chown -R www:www /mnt/files
chmod -R 770 /mnt/files

# Install Additional Database Packages
if [ "${DATABASE}" = "mariadb" ]; then
  pkg install -y mariadb106-server php${PHP_VERSION}-pdo_mysql php${PHP_VERSION}-mysqli
elif [ "${DATABASE}" = "pgsql" ]; then
  pkg install -y postgresql13-server php${PHP_VERSION}-pgsql php${PHP_VERSION}-pdo_pgsql
fi

# Caddy Installation
# Build xcaddy, use it to build Caddy
if ! go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
then
  echo "Failed to get xcaddy, terminating."
  exit 1
fi
if ! cp /root/go/bin/xcaddy /usr/local/bin/xcaddy
then
  echo "Failed to move xcaddy to path, terminating."
  exit 1
fi
if [ ${DNS_CERT} -eq 1 ]; then
  if ! xcaddy build --output /usr/local/bin/caddy --with github.com/caddy-dns/"${DNS_PLUGIN}"
  then
    echo "Failed to build Caddy with ${DNS_PLUGIN} plugin, terminating."
    exit 1
  fi  
else
  if ! xcaddy build --output /usr/local/bin/caddy
  then
    echo "Failed to build Caddy without plugin, terminating."
    exit 1
  fi  
fi
# Generate and install self-signed cert, if necessary
if [ $SELFSIGNED_CERT -eq 1 ]; then
  mkdir -p /usr/local/etc/pki/tls/private
  mkdir -p /usr/local/etc/pki/tls/certs
  openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=${HOST_NAME}" -keyout /tmp/privkey.pem -out /tmp/fullchain.pem
  cp /tmp/privkey.pem /usr/local/etc/pki/tls/private/privkey.pem
  cp /tmp/fullchain.pem /usr/local/etc/pki/tls/certs/fullchain.pem
fi
if [ $STANDALONE_CERT -eq 1 ] || [ $DNS_CERT -eq 1 ]; then
  fetch -o /root/ https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/remove-staging.sh
  chmod +x /root/remove-staging.sh
fi
if [ $NO_CERT -eq 1 ]; then
  echo "Copying Caddyfile for no SSL"
  fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/Caddyfile-nossl
elif [ $SELFSIGNED_CERT -eq 1 ]; then
  echo "Copying Caddyfile for self-signed cert"
  fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/Caddyfile-selfsigned
elif [ $DNS_CERT -eq 1 ]; then
  echo "Copying Caddyfile for Let's Encrypt DNS cert"
  fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/Caddyfile-dns
else
  echo "Copying Caddyfile for Let's Encrypt cert"
  fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/Caddyfile
fi
fetch -o /usr/local/etc/rc.d/caddy https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/caddy
chmod +x /usr/local/etc/rc.d/caddy
sed -i '' "s/yourhostnamehere/${HOST_NAME}/" /usr/local/www/Caddyfile
sed -i '' "s/dns_plugin/${DNS_PLUGIN}/" /usr/local/www/Caddyfile
sed -i '' "s/api_token/${DNS_TOKEN}/" /usr/local/www/Caddyfile
sed -i '' "s/jail_ip/${IP}/" /usr/local/www/Caddyfile
sed -i '' "s/youremailhere/${CERT_EMAIL}/" /usr/local/www/Caddyfile
sysrc caddy_enable="YES"
sysrc caddy_config="/usr/local/www/Caddyfile"
service caddy start

# Nextcloud Download and Verify
FILE="latest-${NEXTCLOUD_VERSION}.tar.bz2"
if ! fetch -o /tmp https://download.nextcloud.com/server/releases/"${FILE}" https://download.nextcloud.com/server/releases/"${FILE}".asc 
then
	echo "Failed to download Nextcloud"
	exit 1
fi
fetch -o /tmp https://nextcloud.com/nextcloud.asc
gpg --import /tmp/nextcloud.asc
if ! gpg --verify /tmp/"${FILE}".asc
then
	echo "GPG Signature Verification Failed!"
	echo "The Nextcloud download is corrupt."
	exit 1
fi
tar xjf /tmp/"${FILE}" -C /usr/local/www/
chown -R www:www /usr/local/www/nextcloud/

# PHP Setup and Start
if ! fetch -o /usr/local/etc/php.ini https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/php.ini
then
	echo "Failed to fetch php.ini"
	exit 1
fi
fetch -o /usr/local/etc/php-fpm.d/ https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/www.conf
if [ "${DATABASE}" = "mariadb" ]; then
  fetch -o /usr/local/etc/mysql/conf.d/nextcloud.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/my-system.cnf
fi
sed -i '' "s|mytimezone|${TIME_ZONE}|" /usr/local/etc/php.ini
chown -R www:www /usr/local/etc/php.ini
sysrc php_fpm_enable="YES"
service php-fpm start

# Redis Setup and Start
fetch -o /usr/local/etc/redis.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/redis.conf
pw usermod www -G redis
sysrc redis_enable="YES"
service redis start
chmod 777 /var/run/redis/redis.sock

#####
#
# Configure Database and Install Nextcloud
#
####

# Enable and start services
if [ "${DATABASE}" = "mariadb" ]; then
  sysrc mysql_enable="YES"
  service mysql-server start
elif [ "${DATABASE}" = "pgsql" ]; then
  sysrc postgresql_enable="YES"
fi
if [ "${REINSTALL}" == "true" ]; then
	echo "Reinstall detected, skipping generation of new config and database"
	if [ "${DATABASE}" = "mariadb" ]; then
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/my.cnf
	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
	elif [ "${DATABASE}" = "pgsql" ]; then
 	fetch -o /root/.pgpass https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/pgpass
  	chmod 600 /root/.pgpass
   	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.pgpass
    	fi
else
if [ "${DATABASE}" = "mariadb" ]; then
  if ! mysql -u root -e "CREATE DATABASE nextcloud;"
  then
    echo "Failed to create MariaDB database, aborting"
    exit 1
  fi
  mysql -u root -e "GRANT ALL ON nextcloud.* TO nextcloud@localhost IDENTIFIED BY '${DB_PASSWORD}';"
  mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
  mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  mysql -u root -e "DROP DATABASE IF EXISTS test;"
  mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  mysqladmin --user=root password "${DB_ROOT_PASSWORD}" reload
  fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/my.cnf
  sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
elif [ "${DATABASE}" = "pgsql" ]; then
  fetch -o /root/.pgpass https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/pgpass
  chmod 600 /root/.pgpass
  chown postgres /var/db/postgres/
  /usr/local/etc/rc.d/postgresql initdb
  su -m postgres -c '/usr/local/bin/pg_ctl -D /var/db/postgres/data13 start'
  sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.pgpass
  if ! psql -U postgres -c "CREATE DATABASE nextcloud;"
  then
    echo "Failed to create PostgreSQL database, aborting"
    exit 1
  fi
  psql -U postgres -c "CREATE USER nextcloud WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';"
  psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;"
  psql -U postgres -c "SELECT pg_reload_conf();"
fi

# Create Nextcloud Log Directory
mkdir -p /var/log/nextcloud/
chown www:www /var/log/nextcloud

# Nextcloud CLI Configuration
if [ "${DATABASE}" = "mariadb" ]; then
  if ! su -m www -c "php /usr/local/www/nextcloud/occ maintenance:install --database=\"mysql\" --database-name=\"nextcloud\" --database-user=\"nextcloud\" --database-pass=\"${DB_PASSWORD}\" --database-host=\"localhost:/var/run/mysql/mysql.sock\" --admin-user=\"admin\" --admin-pass=\"${ADMIN_PASSWORD}\" --data-dir=\"/mnt/files\""
  then
    echo "Failed to install Nextcloud, aborting"
    exit 1
  fi
  su -m www -c "php /usr/local/www/nextcloud/occ config:system:set mysql.utf8mb4 --type boolean --value=\"true\""
elif [ "${DATABASE}" = "pgsql" ]; then
  if ! su -m www -c "php /usr/local/www/nextcloud/occ maintenance:install --database=\"pgsql\" --database-name=\"nextcloud\" --database-user=\"nextcloud\" --database-pass=\"${DB_PASSWORD}\" --database-host=\"localhost:/tmp/.s.PGSQL.5432\" --admin-user=\"admin\" --admin-pass=\"${ADMIN_PASSWORD}\" --data-dir=\"/mnt/files\""
  then
    echo "Failed to install Nextcloud, aborting"
    exit 1
  fi
fi
su -m www -c "php /usr/local/www/nextcloud/occ db:add-missing-indices"
su -m www -c "php /usr/local/www/nextcloud/occ db:convert-filecache-bigint --no-interaction"
su -m www -c "php /usr/local/www/nextcloud/occ config:system:set logtimezone --value=\"${TIME_ZONE}\""
su -m www -c "php /usr/local/www/nextcloud/occ config:system:set default_phone_region --value=\"${COUNTRY_CODE}\""
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set log_type --value="file"'
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set logfile --value="/var/log/nextcloud/nextcloud.log"'
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set loglevel --value="2"'
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set logrotate_size --value="104847600"'
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set memcache.local --value="\OC\Memcache\APCu"'
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set redis host --value="/var/run/redis/redis.sock"'
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set redis port --value=0 --type=integer'
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set memcache.distributed --value="\OC\Memcache\Redis"'
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set memcache.locking --value="\OC\Memcache\Redis"'
su -m www -c "php /usr/local/www/nextcloud/occ config:system:set overwritehost --value=\"${HOST_NAME}\""
if [ $NO_CERT -eq 1 ]; then
  su -m www -c "php /usr/local/www/nextcloud/occ config:system:set overwrite.cli.url --value=\"http://${HOST_NAME}/\""
  su -m www -c "php /usr/local/www/nextcloud/occ config:system:set overwriteprotocol --value=\"http\""
else
  su -m www -c "php /usr/local/www/nextcloud/occ config:system:set overwrite.cli.url --value=\"https://${HOST_NAME}/\""
  su -m www -c "php /usr/local/www/nextcloud/occ config:system:set overwriteprotocol --value=\"https\""
fi
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set htaccess.RewriteBase --value="/"'
su -m www -c 'php /usr/local/www/nextcloud/occ maintenance:update:htaccess'
su -m www -c "php /usr/local/www/nextcloud/occ config:system:set trusted_domains 1 --value=\"${HOST_NAME}\""
su -m www -c "php /usr/local/www/nextcloud/occ config:system:set trusted_domains 2 --value=\"${IP}\""
su -m www -c "php /usr/local/www/nextcloud/occ config:system:set trusted_proxies 1 --value=\"127.0.0.1\""
su -m www -c 'php /usr/local/www/nextcloud/occ background:cron'
fi
su -m www -c 'php -f /usr/local/www/nextcloud/cron.php'
fetch -o /tmp/www-crontab https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/www-crontab
crontab -u www /tmp/www-crontab
su -m www -c "php /usr/local/www/nextcloud/occ config:system:set maintenance_window_start --type=integer --value=${MX_WINDOW}"

# Restart Services
service mysql-server restart
service redis restart
service php-fpm restart
service caddy restart

# Save passwords for later reference
echo "${DB_NAME} root password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}_db_password.txt
echo "Nextcloud database password is ${DB_PASSWORD}" >> /root/${APP_NAME}_db_password.txt
echo "Nextcloud Administrator password is ${ADMIN_PASSWORD}" >> /root/${APP_NAME}_db_password.txt

echo "Installation complete!"
if [ $NO_CERT -eq 1 ]; then
  echo "Using your web browser, go to http://${HOST_NAME} to log in"
else
  echo "Using your web browser, go to https://${HOST_NAME} to log in"
fi

if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, please use your old database and account credentials"
else

	echo "Default user is admin, password is ${ADMIN_PASSWORD}"
	echo ""
	echo "Database Information"
	echo "--------------------"
	echo "Database user = nextcloud"
	echo "Database password = ${DB_PASSWORD}"
	echo "The ${DB_NAME} root password is ${DB_ROOT_PASSWORD}"
	echo ""
	echo "All passwords are saved in /root/${APP_NAME}_db_password.txt"
fi

echo ""
if [ $STANDALONE_CERT -eq 1 ] || [ $DNS_CERT -eq 1 ]; then
  echo "You have obtained your Let's Encrypt certificate using the staging server."
  echo "This certificate will not be trusted by your browser and will cause SSL errors"
  echo "when you connect.  Once you've verified that everything else is working"
  echo "correctly, you should issue a trusted certificate.  To do this, run:"
  echo "  iocage exec ${JAIL_NAME} /root/remove-staging.sh"
  echo ""
elif [ $SELFSIGNED_CERT -eq 1 ]; then
  echo "You have chosen to create a self-signed TLS certificate for your Nextcloud"
  echo "installation.  This certificate will not be trusted by your browser and"
  echo "will cause SSL errors when you connect.  If you wish to replace this certificate"
  echo "with one obtained elsewhere, the private key is located at:"
  echo "/usr/local/etc/pki/tls/private/privkey.pem"
  echo "The full chain (server + intermediate certificates together) is at:"
  echo "/usr/local/etc/pki/tls/certs/fullchain.pem"
  echo ""
fi
