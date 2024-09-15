#!/bin/sh
# Install Zenphoto

APP_NAME="zenphoto"
DATABASE_TYPE="MariaDB"
DB_NAME="zenphoto"
DB_USER="zenphoto"
DB_ROOT_PASSWORD=$(openssl rand -base64 15)
DB_PASSWORD=$(openssl rand -base64 15)
ZP_VERSION="1.6.4"
MARIADB_VERSION="106"
PHP_VERSION="83"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ "$(ls -A /var/db/mysql/"${DB_NAME}" 2>/dev/null)" ]; then
	echo "Existing Zenphoto database detected. Checking compatability for reinstall."
  REINSTALL="true"
fi

# Install Packages
pkg install -y caddy mariadb${MARIADB_VERSION}-server mariadb${MARIADB_VERSION}-client mysql-connector-j php${PHP_VERSION} php${PHP_VERSION}-bz2 php${PHP_VERSION}-ctype php${PHP_VERSION}-curl php${PHP_VERSION}-dom php${PHP_VERSION}-exif php${PHP_VERSION}-fileinfo php${PHP_VERSION}-filter php${PHP_VERSION}-gd php${PHP_VERSION}-gettext php${PHP_VERSION}-iconv php${PHP_VERSION}-intl php${PHP_VERSION}-mbstring php${PHP_VERSION}-mysqli php${PHP_VERSION}-pdo_mysql php${PHP_VERSION}-session php${PHP_VERSION}-simplexml php${PHP_VERSION}-tidy php${PHP_VERSION}-xml php${PHP_VERSION}-xmlreader php${PHP_VERSION}-xmlwriter php${PHP_VERSION}-zip

# Create Directories
mkdir -p /var/db/mysql
mkdir -p /usr/local/www/zenphoto

# Create Database
sysrc mysql_enable="YES"
service mysql-server start
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, please use your old database credentials."
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zenphoto/includes/my.cnf
  sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
else
	if ! mysql -u root -e "CREATE DATABASE ${DB_NAME};"; then
		echo "Failed to create MariaDB database, aborting"
		exit 1
	fi
		mysql -u root -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@localhost IDENTIFIED BY '${DB_PASSWORD}';"
		mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
		mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
		mysql -u root -e "DROP DATABASE IF EXISTS test;"
		mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
		mysql -u root -e "FLUSH PRIVILEGES;"
		mysqladmin --user=root password "${DB_ROOT_PASSWORD}" reload
		fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zenphoto/includes/my.cnf
		sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
fi

# Install Zenphoto
FILE="v${ZP_VERSION}.tar.gz"
fetch -o /tmp https://github.com/zenphoto/zenphoto/archive/"${FILE}"
tar xjf /tmp/"${FILE}" -C /tmp/
if [ "${REINSTALL}" == "true" ]; then
  rm -R /usr/local/www/zenphoto/zp-core
  cp -R -f /tmp/zenphoto-"${ZP_VERSION}"/zp-core /usr/local/www/zenphoto/
  mv -R /usr/local/www/zenphoto/themes /usr/local/www/zenphoto/themes.bak
  rm -R /usr/local/www/zenphoto/themes
  cp -R -f /tmp/zenphoto-"${ZP_VERSION}"/themes /usr/local/www/zenphoto/themes
  cp -f /tmp/zenphoto-"${ZP_VERSION}"/index.php /usr/local/www/zenphoto/index.php
  chown -R www:www /usr/local/www/zenphoto
  rm -R /tmp/"${FILE}" /tmp/zenphoto-"${ZP_VERSION}"
else
  cp -r -f /tmp/zenphoto-"${ZP_VERSION}"/ /usr/local/www/zenphoto/
  rm -R /tmp/"${FILE}" /tmp/zenphoto-"${ZP_VERSION}"
  fetch -o /usr/local/www/zenphoto/zp-data/zenphoto.cfg.php.bak https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zenphoto/includes/zenphoto.cfg.php
  cp -f /usr/local/www/zenphoto/zp-data/zenphoto.cfg.php.bak /usr/local/www/zenphoto/zp-data/zenphoto.cfg.php
  sed -i '' "s/zenphoto_db_user/${DB_USER}/" /usr/local/www/zenphoto/zp-data/zenphoto.cfg.php
  sed -i '' "s|zenphoto_db_pass|${DB_PASSWORD}|" /usr/local/www/zenphoto/zp-data/zenphoto.cfg.php
  sed -i '' "s|zenphoto_db_socket|/var/run/mysql/mysql.sock|" /usr/local/www/zenphoto/zp-data/zenphoto.cfg.php
  sed -i '' "s/zenphoto_db/${DB_NAME}/" /usr/local/www/zenphoto/zp-data/zenphoto.cfg.php
  touch /usr/local/www/zenphoto/zp-data/charset_tést
  chown -R www:www /usr/local/www/zenphoto
fi
fetch -o /usr/local/etc/php.ini https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zenphoto/includes/php.ini
chown -R www:www /usr/local/etc/php.ini

# Caddy Setup
fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/zenphoto/includes/Caddyfile-nossl
sysrc caddy_config="/usr/local/www/Caddyfile"
sysrc caddy_enable="YES"

# Enable and Start Services
sysrc php_fpm_enable="YES"
service caddy start
service php-fpm start


echo "---------------"
echo "Installation complete."
echo "Zenphoto is running on port 80"
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, please user your old credentials to log in."
else
  echo "Database Information"
  echo "MySQL Username: root"
  echo "MySQL Password: $DB_ROOT_PASSWORD"
  echo "Zenphoto DB User: $DB_USER"
  echo "Zenphoto DB Password: "$DB_PASSWORD""
  echo "---------------"
	echo "User Information"
	echo "Admin user is created on setup."
fi
echo "All passwords are saved in /root/${APP_NAME}_db_password.txt"
echo "---------------"
