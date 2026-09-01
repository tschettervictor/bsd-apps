#!/bin/sh
# Install Observium

APP_NAME="Observium"
APP_VERSION="latest"
ADMIN_PASSWORD="$(openssl rand -base64 12)"
DB_TYPE="MariaDB"
DB_NAME="observium"
DB_USER="observium"
DB_ROOT_PASSWORD="$(openssl rand -base64 15)"
DB_PASSWORD="$(openssl rand -base64 15)"
MARIADB_VERSION="123"
PHP_VERSION="84"
PYTHON_VERSION="312"
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

# Switch to Latest Repo
mkdir -p /usr/local/etc/pkg/repos
cp /etc/pkg/FreeBSD.conf /usr/local/etc/pkg/repos/
sed -i '' "s/quarterly/latest/" /usr/local/etc/pkg/repos/FreeBSD.conf

# Packages
pkg install -y \
fping \
git-tiny \
go \
graphviz \
ImageMagick7-nox11 \
ipmitool \
mariadb"${MARIADB_VERSION}"-server \
mtr-nox11 \
nagios-plugins \
net-snmp \
nmap \
php"${PHP_VERSION}" \
php"${PHP_VERSION}"-bcmath \
php"${PHP_VERSION}"-ctype \
php"${PHP_VERSION}"-curl \
php"${PHP_VERSION}"-filter \
php"${PHP_VERSION}"-gd \
php"${PHP_VERSION}"-mbstring \
php"${PHP_VERSION}"-mysqli \
php"${PHP_VERSION}"-posix \
php"${PHP_VERSION}"-session \
php"${PHP_VERSION}"-sodium \
php"${PHP_VERSION}"-pear-Services_JSON \
php"${PHP_VERSION}"-pecl-APCu \
php"${PHP_VERSION}"-pecl-mcrypt \
python \
python3 \
py"${PYTHON_VERSION}"-pymysql \
rancid3 \
rrdtool

# Directories/Files
mkdir -p /var/db/mysql
mkdir -p /var/db/observium/config
mkdir -p /var/db/observium/logs
mkdir -p /var/db/observium/rrd
mkdir -p /opt/observium
mkdir -p /usr/local/etc/cron.d
mkdir -p /usr/local/www
touch /var/db/observium/config/config.php
ln -sf /var/db/observium/config/config.php /opt/observium/config.php
chown -R 88:88 /var/db/mysql
chown -R www:www /opt/observium
chown -R www:www /var/db/observium

# Database
sysrc mysql_enable="YES"
service mysql-server start
if [ "${REINSTALL}" = "true" ]; then
	echo "You did a reinstall, but database passwords will still be changed."
 	echo "New passwords will still be saved in the root directory."
 	mysql -u root -e "SET PASSWORD FOR '${DB_USER}'@localhost = PASSWORD('${DB_PASSWORD}');"
  	sed -i '' "s|.*['db_pass'].*=.*|\$config['db_pass']      = \'${DB_PASSWORD}\'\;|" /opt/observium/config.php
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/observium/includes/my.cnf
  	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
else
	if ! mysql -u root -e "CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"; then
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
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/observium/includes/my.cnf
	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
fi
service mysql-server restart

# RRD
sysrc rrdcached_enable="YES"
service rrdcached start

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
	fetch -o /root/ https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/observium/includes/remove-staging.sh
  	chmod +x /root/remove-staging.sh
fi
if [ "${NO_CERT}" -eq 1 ]; then
	echo "Fetching Caddyfile for no SSL"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/observium/includes/Caddyfile-nossl
elif [ "${SELFSIGNED_CERT}" -eq 1 ]; then
	echo "Fetching Caddyfile for self-signed cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/observium/includes/Caddyfile-selfsigned
elif [ "${DNS_CERT}" -eq 1 ]; then
  	echo "Fetching Caddyfile for Let's Encrypt DNS cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/observium/includes/Caddyfile-dns
else
  	echo "Fetching Caddyfile for Let's Encrypt cert"
  	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/observium/includes/Caddyfile
fi
fetch -o /usr/local/etc/rc.d/caddy https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/observium/includes/caddy
chmod +x /usr/local/etc/rc.d/caddy
sed -i '' "s/yourhostnamehere/${HOST_NAME}/" /usr/local/www/Caddyfile
sed -i '' "s/dns_plugin/${DNS_PLUGIN}/" /usr/local/www/Caddyfile
sed -i '' "s/api_token/${DNS_TOKEN}/" /usr/local/www/Caddyfile
sed -i '' "s/youremailhere/${CERT_EMAIL}/" /usr/local/www/Caddyfile
sysrc caddy_enable="YES"
sysrc caddy_config="/usr/local/www/Caddyfile"
service caddy start

# Observium
fetch -o /tmp/"${APP_NAME}".tar.gz https://www.observium.org/observium-community-"${APP_VERSION}".tar.gz
tar -xv -f /tmp/"${APP_NAME}".tar.gz --strip-components=1 -C /opt/observium
rm -r /tmp/"${APP_NAME}"*
chown -R www:www /opt/observium
if [ "${REINSTALL}" != "true" ]; then
    if [ "${NO_CERT}" -eq 1 ]; then
        PROTO="http"
    else
        PROTO="https"
    fi
    cat > /opt/observium/config.php <<EOF
<?php

\$config['db_extension'] = 'mysqli';
\$config['db_host']      = '127.0.0.1';
\$config['db_user']      = 'observium';
\$config['db_pass']      = '${DB_PASSWORD}';
\$config['db_name']      = 'observium';

\$config['base_url']     = '${PROTO}://${HOST_NAME}';

\$config['rrd_dir']      = "/var/db/observium/rrd";
\$config['log_dir']      = "/var/db/observium/logs";

\$config['rrdtool']                   = "/usr/local/bin/rrdtool";
\$config['fping']                     = "/usr/local/sbin/fping";
\$config['fping6']                    = "/usr/local/sbin/fping6";
\$config['snmpwalk']                  = "/usr/local/bin/snmpwalk";
\$config['snmpget']                   = "/usr/local/bin/snmpget";
\$config['snmpgetnext']               = "/usr/local/bin/snmpgetnext";
\$config['snmpbulkget']               = "/usr/local/bin/snmpbulkget";
\$config['snmpbulkwalk']              = "/usr/local/bin/snmpbulkwalk";
\$config['snmptranslate']             = "/usr/local/bin/snmptranslate";
\$config['mtr']                       = "/usr/local/sbin/mtr";
\$config['nmap']                      = "/usr/local/bin/nmap";
\$config['ipmitool']                  = "/usr/local/bin/ipmitool";
\$config['git']                       = "/usr/local/bin/git";
\$config['dot']                       = "/usr/local/bin/dot";
\$config['unflatten']                 = "/usr/local/bin/unflatten";
\$config['neato']                     = "/usr/local/bin/neato";
\$config['sfdp']                      = "/usr/local/bin/sfdp";

\$config['nagplug_dir']               = "/usr/local/libexec/nagios";
\$config['rrdcached']                 = "unix:/var/run/rrdcached.sock";
EOF
/opt/observium/discovery.php -u
/opt/observium/adduser.php admin "${ADMIN_PASSWORD}" 10
fi
chown www:www /var/db/observium/config/config.php
chmod 600 /var/db/observium/config/config.php
cat > /usr/local/etc/cron.d/observium <<EOF
# Run a complete discovery of all devices once every 6 hours
33 */6 * * * /opt/observium/observium-wrapper discovery >/dev/null 2>&1
# Run automated discovery of newly added devices every 5 minutes
*/5 * * * * /opt/observium/observium-wrapper discovery --host new >/dev/null 2>&1
# Run multithreaded poller wrapper every 5 minutes
*/5 * * * * /opt/observium/observium-wrapper poller >/dev/null 2>&1
# Run housekeeping script daily for syslog, eventlog and alert log
13 5 * * * /opt/observium/housekeeping.php -ysel >/dev/null 2>&1
# Run housekeeping script daily for rrds, ports, orphaned entries in the database and performance data
47 4 * * * /opt/observium/housekeeping.php -yrptb >/dev/null 2>&1
EOF

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
