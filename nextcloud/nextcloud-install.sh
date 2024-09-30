#!/bin/sh
# Install Nextcloud

APP_NAME="Nextcloud"
APP_VERSION="29"
ADMIN_PASSWORD=$(openssl rand -base64 12)
MX_WINDOW="5"
DATABASE="mariadb"
DB_NAME="nextcloud"
DB_USER="nextcloud"
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
PG_VERSION="13"

if [ ${DATABASE} = "mariadb" ]; then
	DB_PATH="/var/db/mysql"
 	DB_TYPE="MariaDB"
elif [ ${DATABASE} = "pgsql" ]; then
	DB_PATH="/var/db/postgres"
 	DB_TYPE="PostgreSQL"
fi

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

# Check for Reinstall
if [ "$(ls -A "${DB_PATH}"/nextcloud 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} database detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Package Installation
pkg install -y nano sudo vim redis gnupg bash go git ffmpeg perl5 p5-Locale-gettext help2man texinfo m4 autoconf openssl php${PHP_VERSION} php${PHP_VERSION}-ctype php${PHP_VERSION}-curl php${PHP_VERSION}-dom php${PHP_VERSION}-filter php${PHP_VERSION}-gd php${PHP_VERSION}-xml php${PHP_VERSION}-mbstring php${PHP_VERSION}-posix php${PHP_VERSION}-session php${PHP_VERSION}-simplexml php${PHP_VERSION}-xmlreader php${PHP_VERSION}-xmlwriter php${PHP_VERSION}-zip php${PHP_VERSION}-zlib php${PHP_VERSION}-fileinfo php${PHP_VERSION}-bz2 php${PHP_VERSION}-intl php${PHP_VERSION}-ldap php${PHP_VERSION}-pecl-smbclient php${PHP_VERSION}-ftp php${PHP_VERSION}-imap php${PHP_VERSION}-bcmath php${PHP_VERSION}-gmp php${PHP_VERSION}-exif php${PHP_VERSION}-pecl-APCu php${PHP_VERSION}-pecl-memcache php${PHP_VERSION}-pecl-redis php${PHP_VERSION}-pecl-imagick php${PHP_VERSION}-pcntl php${PHP_VERSION}-phar php${PHP_VERSION}-iconv php${PHP_VERSION}-sodium php${PHP_VERSION}-sysvsem php${PHP_VERSION}-xsl php${PHP_VERSION}-opcache

# Create Directories
if [ "${DB_TYPE}" = "MariaDB" ]; then
  mkdir -p /var/db/mysql
elif [ "${DB_TYPE}" = "PostgreSQL" ]; then
  mkdir -p /var/db/postgres
fi
mkdir -p /mnt/files
mkdir -p /usr/local/www/nextcloud/config
mkdir -p /usr/local/www/nextcloud/themes
mkdir -p /var/log/nextcloud/
chown -R www:www /var/log/nextcloud
chown -R www:www /mnt/files
chmod -R 770 /mnt/files

# Install Additional Database Packages
if [ "${DB_TYPE}" = "MariaDB" ]; then
  pkg install -y mariadb${MARIADB_VERSION}-server php${PHP_VERSION}-pdo_mysql php${PHP_VERSION}-mysqli
elif [ "${DB_TYPE}" = "PostgreSQL" ]; then
  pkg install -y postgresql${PG_VERSION}-server php${PHP_VERSION}-pgsql php${PHP_VERSION}-pdo_pgsql
fi

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
	fetch -o /root/ https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/remove-staging.sh
  	chmod +x /root/remove-staging.sh
fi
if [ $NO_CERT -eq 1 ]; then
	echo "Fetching Caddyfile for no SSL"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/Caddyfile-nossl
elif [ $SELFSIGNED_CERT -eq 1 ]; then
	echo "Fetching Caddyfile for self-signed cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/Caddyfile-selfsigned
elif [ $DNS_CERT -eq 1 ]; then
  	echo "Fetching Caddyfile for Let's Encrypt DNS cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/Caddyfile-dns
else
  	echo "Fetching Caddyfile for Let's Encrypt cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/Caddyfile
fi
fetch -o /usr/local/etc/rc.d/caddy https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/caddy
chmod +x /usr/local/etc/rc.d/caddy
sed -i '' "s/yourhostnamehere/${HOST_NAME}/" /usr/local/www/Caddyfile
sed -i '' "s/dns_plugin/${DNS_PLUGIN}/" /usr/local/www/Caddyfile
sed -i '' "s/api_token/${DNS_TOKEN}/" /usr/local/www/Caddyfile
sed -i '' "s/youremailhere/${CERT_EMAIL}/" /usr/local/www/Caddyfile
sysrc caddy_enable="YES"
sysrc caddy_config="/usr/local/www/Caddyfile"
service caddy start

# Nextcloud Download
FILE="latest-${APP_VERSION}.tar.bz2"
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

# PHP Setup
fetch -o /usr/local/etc/php.ini https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/php.ini
fetch -o /usr/local/etc/php-fpm.d/ https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/www.conf
if [ "${DB_TYPE}" = "MariaDB" ]; then
  fetch -o /usr/local/etc/mysql/conf.d/nextcloud.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/my-system.cnf
fi
sed -i '' "s|mytimezone|${TIME_ZONE}|" /usr/local/etc/php.ini
chown -R www:www /usr/local/etc/php.ini
sysrc php_fpm_enable="YES"
service php-fpm start

# Redis Setup
fetch -o /usr/local/etc/redis.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/redis.conf
pw usermod www -G redis
sysrc redis_enable="YES"
service redis start
chmod 777 /var/run/redis/redis.sock

# Create and Configure Database
if [ "${DB_TYPE}" = "MariaDB" ]; then
	sysrc mysql_enable="YES"
  	service mysql-server start
elif [ "${DB_TYPE}" = "PostgreSQL" ]; then
  	sysrc postgresql_enable="YES"
fi
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, but the ${DB_TYPE} root password AND ${APP_NAME} database password will be changed."
 	echo "New passwords will be saved in the root directory."
	if [ "${DB_TYPE}" = "MariaDB" ]; then
   		mysql -u root -e "SET PASSWORD FOR '${DB_USER}'@localhost = PASSWORD('${DB_PASSWORD}');"
		fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/my.cnf
		sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
	elif [ "${DB_TYPE}" = "PostgreSQL" ]; then
 		psql -U postgres -c "ALTER USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"
 		fetch -o /root/.pgpass https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/pgpass
  		chmod 600 /root/.pgpass
   		sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.pgpass
    	fi
     	sed -i '' "s|.*dbpassword.*|  'dbpassword' => '${DB_PASSWORD}',|" /usr/local/www/nextcloud/config/config.php
else
	if [ "${DB_TYPE}" = "MariaDB" ]; then
		if ! mysql -u root -e "CREATE DATABASE ${DB_NAME};"
                        then
			echo "Failed to create ${APP_NAME} database, aborting"
			exit 1
		fi
		mysql -u root -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@localhost IDENTIFIED BY '${DB_PASSWORD}';"
		mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
	  	mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
	  	mysql -u root -e "DROP DATABASE IF EXISTS test;"
	  	mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
	  	mysqladmin --user=root password "${DB_ROOT_PASSWORD}" reload
	  	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/my.cnf
	  	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
	elif [ "${DB_TYPE}" = "PostgreSQL" ]; then
	  	fetch -o /root/.pgpass https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/pgpass
	  	chmod 600 /root/.pgpass
    	  	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.pgpass
    		mkdir /var/db/postgres
	  	chown postgres /var/db/postgres
	  	service postgresql initdb
	  	service postgresql start
	  	if ! psql -U postgres -c "CREATE DATABASE ${DB_NAME} TEMPLATE template0 ENCODING 'UTF8';"
                        then
			echo "Failed to create ${APP_NAME} database, aborting"
			exit 1
	  	fi
	  	psql -U postgres -c "CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';"
	  	psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
    	  	psql -U postgres -c "GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};"
		psql -U postgres -c "ALTER DATABASE ${DB_NAME} OWNER TO ${DB_USER};"
	  	psql -U postgres -c "SELECT pg_reload_conf();"
	fi

# Nextcloud Setup
	if [ "${DB_TYPE}" = "MariaDB" ]; then
		if ! su -m www -c "php /usr/local/www/nextcloud/occ maintenance:install --database=\"mysql\" --database-name=\"${DB_NAME}\" --database-user=\"${DB_USER}\" --database-pass=\"${DB_PASSWORD}\" --database-host=\"localhost:/var/run/mysql/mysql.sock\" --admin-user=\"admin\" --admin-pass=\"${ADMIN_PASSWORD}\" --data-dir=\"/mnt/files\""
  			then
    			echo "Failed to install ${APP_NAME}, aborting"
    			exit 1
		fi
	su -m www -c "php /usr/local/www/nextcloud/occ config:system:set mysql.utf8mb4 --type boolean --value=\"true\""
	elif [ "${DATABASE}" = "pgsql" ]; then
  		if ! su -m www -c "php /usr/local/www/nextcloud/occ maintenance:install --database=\"pgsql\" --database-name=\"${DB_NAME}\" --database-user=\"${DB_USER}\" --database-pass=\"${DB_PASSWORD}\" --database-host=\"localhost:/tmp/.s.PGSQL.5432\" --admin-user=\"admin\" --admin-pass=\"${ADMIN_PASSWORD}\" --data-dir=\"/mnt/files\""
  			then
    			echo "Failed to install ${APP_NAME}, aborting"
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
 	su -m www -c "php /usr/local/www/nextcloud/occ config:system:set maintenance_window_start --type=integer --value=${MX_WINDOW}"
	su -m www -c 'php /usr/local/www/nextcloud/occ background:cron'
fi
su -m www -c 'php -f /usr/local/www/nextcloud/cron.php'
fetch -o /tmp/www-crontab https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/nextcloud/includes/www-crontab
crontab -u www /tmp/www-crontab

# Restart Services
service mysql-server restart
service redis restart
service php-fpm restart
service caddy restart

# Save Passwords
echo "${DB_TYPE} root password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}-Info.txt
echo "${APP_NAME} database password is ${DB_PASSWORD}" >> /root/${APP_NAME}-Info.txt
echo "${APP_NAME} admin password is ${ADMIN_PASSWORD}" >> /root/${APP_NAME}-Info.txt

echo "---------------"
echo "Installation complete!"
echo "---------------"
echo "Database Information"
echo "$DB_TYPE Username: root"
echo "$DB_TYPE Password: $DB_ROOT_PASSWORD"
echo "$APP_NAME DB User: $DB_USER"
echo "$APP_NAME DB Password: $DB_PASSWORD"
echo "--------------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall."
	echo "Please user your old credentials to log in."
        echo "---------------"
else
	echo "User Information"
	echo "Default ${APP_NAME} user is admin"
	echo "Default ${APP_NAME} password is ${ADMIN_PASSWORD}"
     	echo "--------------------"
fi
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
	echo "Using your web browser, go to http://${HOST_NAME} to log in"
 	echo "--------------------"
else
	echo "Using your web browser, go to https://${HOST_NAME} to log in"
 	echo "--------------------"
fi
