#!/bin/sh
# Install Apache Guacamole

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

MARIADB_VERSION="106"
DB_PATH="/var/db/mysql"
DATABASE="mariadb"
DB_NAME="guacamole"
DB_USER="guacamole"
DB_ROOT_PASSWORD=$(openssl rand -base64 15)
DB_PASSWORD=$(openssl rand -base64 15)

# Check for reinstall
if [ "$(ls -A "${DB_PATH}")" ]; then
	echo "Existing Guacamole database detected. Checking compatability for reinstall."
	if [ "$(ls -A "${DB_PATH}/${DATABASE}")" ]; then
		echo "Database is compatible, continuing..."
		REINSTALL="true"
	else
		echo "ERROR: You can not reinstall without the previous database"
		echo "Please try again after removing the database, or using the same database used previously"
		exit 1
	fi
fi

# Package installation
pkg install -y guacamole-server guacamole-client mariadb"${MARIADB_VERSION}"-server mariadb"${MARIADB_VERSION}"-client mysql-connector-j

# Create directories
mkdir -p "${DB_PATH}"
mkdir -p /usr/local/etc/guacamole-client/lib
mkdir -p /usr/local/etc/guacamole-client/extensions

# Enable services
sysrc guacd_enable="YES"
sysrc tomcat9_enable="YES"
sysrc mysql_enable="YES"

# Extract java connector to guacamole
cp -f /usr/local/share/java/classes/mysql-connector-j.jar /usr/local/etc/guacamole-client/lib
tar xvfz /usr/local/share/guacamole-client/guacamole-auth-jdbc.tar.gz -C /tmp/
cp -f /tmp/guacamole-auth-jdbc-*/mysql/*.jar /usr/local/etc/guacamole-client/extensions

# Copy guacamole server files
cp -f /usr/local/etc/guacamole-server/guacd.conf.sample /usr/local/etc/guacamole-server/guacd.conf
cp -f /usr/local/etc/guacamole-client/logback.xml.sample /usr/local/etc/guacamole-client/logback.xml
cp -f /usr/local/etc/guacamole-client/guacamole.properties.sample /usr/local/etc/guacamole-client/guacamole.properties

# Change default bind host ip
sed -i -e 's/'localhost'/'0.0.0.0'/g' /usr/local/etc/guacamole-server/guacd.conf

# Add database connection
echo "mysql-hostname: localhost" >> /usr/local/etc/guacamole-client/guacamole.properties
echo "mysql-port:     3306" >> /usr/local/etc/guacamole-client/guacamole.properties
echo "mysql-database: '${DB_NAME}'" >> /usr/local/etc/guacamole-client/guacamole.properties
echo "mysql-username: '${DB_USER}'" >> /usr/local/etc/guacamole-client/guacamole.properties
echo "mysql-password: '${DB_PASSWORD}'" >> /usr/local/etc/guacamole-client/guacamole.properties
service mysql-server start

if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, but database passwords will still be changed."
 	echo "New passwords will still be saved in the root directory."
 	mysql -u root -e "SET PASSWORD FOR '${DB_USER}'@localhost = PASSWORD('${DB_PASSWORD}');"
  fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/apache-guacamole/my.cnf
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
		fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/apache-guacamole/my.cnf
		sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
		cat /tmp/guacamole-auth-jdbc-*/mysql/schema/*.sql | mysql -u root -p"${DB_ROOT_PASSWORD}" ${DB_NAME}
fi

# Restart services
service mysql-server restart
service guacd restart
service tomcat9 restart

# Save passwords for later reference
echo "${DATABASE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}_db_password.txt
echo "Guacamole database user is ${DB_USER} and password is ${DB_PASSWORD}" >> /root/${APP_NAME}_db_password.txt
echo "Guacamole default username and password are both guacadmin." >> /root/${APP_NAME}_db_password.txt

echo "---------------"
echo "Installation complete."
echo "---------------"
echo "Database Information"
echo "MySQL Username: root"
echo "MySQL Password: $DB_ROOT_PASSWORD"
echo "Guacamole DB User: $DB_USER"
echo "Guacamole DB Password: "$DB_PASSWORD""
if [ "${REINSTALL}" == "true" ]; then
	echo "---------------"
	echo "You did a reinstall, please user your old credentials to log in."
else
	echo "---------------"
	echo "User Information"
	echo "Default user is guacadmin"
	echo "Default password is guacadmin"
fi
echo "---------------"
echo "All passwords are saved in /root/${APP_NAME}_db_password.txt"
echo "---------------"
