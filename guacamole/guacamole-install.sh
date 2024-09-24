#!/bin/sh
# Install Apache Guacamole

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

APP_NAME="Guacamole"
MARIADB_VERSION="106"
DB_TYPE="MariaDB"
DB_NAME="guacamole"
DB_USER="guacamole"
DB_ROOT_PASSWORD=$(openssl rand -base64 15)
DB_PASSWORD=$(openssl rand -base64 15)

# Check for Reinstall
if [ "$(ls -A /var/db/mysql/"${DB_NAME}" 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} database detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Package Installation
pkg install -y guacamole-server guacamole-client mariadb"${MARIADB_VERSION}"-server mariadb"${MARIADB_VERSION}"-client mysql-connector-j

# Create Directories
mkdir -p /var/db/mysql
chown -R 88:88 /var/db/mysql
mkdir -p /usr/local/etc/guacamole-client/lib
mkdir -p /usr/local/etc/guacamole-client/extensions

# Enable Services
sysrc guacd_enable="YES"
sysrc tomcat9_enable="YES"
sysrc mysql_enable="YES"

# Configure Guacamole 
cp -f /usr/local/share/java/classes/mysql-connector-j.jar /usr/local/etc/guacamole-client/lib
tar xvfz /usr/local/share/guacamole-client/guacamole-auth-jdbc.tar.gz -C /tmp/
cp -f /tmp/guacamole-auth-jdbc-*/mysql/*.jar /usr/local/etc/guacamole-client/extensions
cp -f /usr/local/etc/guacamole-server/guacd.conf.sample /usr/local/etc/guacamole-server/guacd.conf
cp -f /usr/local/etc/guacamole-client/logback.xml.sample /usr/local/etc/guacamole-client/logback.xml
sed -i -e 's/'localhost'/'0.0.0.0'/g' /usr/local/etc/guacamole-server/guacd.conf

# Create and Configure Database
service mysql-server start
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, but database passwords will still be changed."
 	echo "New passwords will still be saved in the root directory."
 	mysql -u root -e "SET PASSWORD FOR '${DB_USER}'@localhost = PASSWORD('${DB_PASSWORD}');"
  	sed -i '' -e "s|.*mysql-password.*|mysql-password: ${DB_PASSWORD}|g" /usr/local/etc/guacamole-client/guacamole.properties
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/guacamole/includes/my.cnf
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
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/guacamole/includes/my.cnf
	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
	cat /tmp/guacamole-auth-jdbc-*/mysql/schema/*.sql | mysql -u root -p"${DB_ROOT_PASSWORD}" ${DB_NAME}
	cp -f /usr/local/etc/guacamole-client/guacamole.properties.sample /usr/local/etc/guacamole-client/guacamole.properties
  	echo "mysql-hostname: localhost" >> /usr/local/etc/guacamole-client/guacamole.properties
	echo "mysql-port:     3306" >> /usr/local/etc/guacamole-client/guacamole.properties
	echo "mysql-database: ${DB_NAME}" >> /usr/local/etc/guacamole-client/guacamole.properties
	echo "mysql-username: ${DB_USER}" >> /usr/local/etc/guacamole-client/guacamole.properties
	echo "mysql-password: ${DB_PASSWORD}" >> /usr/local/etc/guacamole-client/guacamole.properties
fi

# Restart Services
service mysql-server restart
service guacd restart
service tomcat9 restart

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
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "---------------"
else
	echo "User Information"
	echo "Default ${APP_NAME} user is guacadmin"
	echo "Default ${APP_NAME} password is guacadmin"
	echo "---------------"
fi
echo "All passwords are saved in /root/${APP_NAME}-Info.txt"
echo "---------------"
