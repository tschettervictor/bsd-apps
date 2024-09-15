#!/bin/sh
# Install and configure your selected database with predefined variables

MARIADB=0
MARIADB_VERSION="106"
MYSQL=0
MYSQL_VERSION="81"
POSTGRESQL=0
PGSQL_VERSION="15"
DB_NAME=""
DB_USER=""
DB_ROOT_PASSWORD=$(openssl rand -base64 15)
DB_PASSWORD=$(openssl rand -base64 15)

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check Variables
if [ $MARIADB -eq 0 ] && [ $MYSQL -eq 0 ] && [ $POSTGRESQL -eq 0 ]; then
  echo 'Configuration error: Either MariaDB, MySQL, or PostgreSQL must be set to 1.'
  exit 1
fi
if [ $MARIADB -eq 1 ] && [ $MYSQL -eq 1 ]; then
  echo 'Configuration error: Only one of MariaDB, MySQL, or PostgreSQL may be set to 1.'
  exit 1
fi
if [ $MARIADB -eq 1 ] && [ $POSTGRESQL -eq 1 ]; then
  echo 'Configuration error: Only one of MariaDB, MySQL, or PostgreSQL may be set to 1.'
  exit 1
fi
if [ $POSTGRESQL -eq 1 ] && [ $MYSQL -eq 1 ]; then
  echo 'Configuration error: Only one of MariaDB, MySQL, or PostgreSQL may be set to 1.'
  exit 1
fi
if [ $MARIADB -eq 1 ]; then
	DATABASE_TYPE="MariaDB"
elif [ $MYSQL -eq 1 ]; then
	DATABASE_TYPE="MySQL"
elif [ $POSTGRESQL -eq 1 ]; then
	DATABASE_TYPE="PostgreSQL"
fi
if [ -z "${DATABASE_TYPE}" ]; then
  echo 'Configuration error: DATABASE must be set'
  exit 1
fi
if [ -z "${DB_NAME}" ]; then
  echo 'Configuration error: DB_NAME must be set'
  exit 1
fi
if [ -z "${DB_USER}" ]; then
  echo 'Configuration error: DB_USER must be set'
  exit 1
fi

# Install Database
echo "You have chosen to install ${DATABASE_TYPE}. Proceeding with setup..."
if [ "${MARIADB}" = 1 ]; then
	pkg install -y mariadb${MARIADB_VERSION}-server mariadb${MARIADB_VERSION}-client
	sysrc mysql_enable=yes
	service mysql-server start
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
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/database/includes/my.cnf
	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
elif [ "${MYSQL}" = 1 ]; then
	pkg install -y mysql${MYSQL_VERSION}-server mysql${MYSQL_VERSION}-client
	sysrc mysql_enable=yes
	service mysql-server start
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
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/database/includes/my.cnf
	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
elif [ "${POSTGRESQL}" = 1 ]; then
	pkg install -y postgresql${PGSQL_VERSION}-server postgresql${PGSQL_VERSION}-client
	sysrc postgresql_enable=yes
	fetch -o /root/.pgpass https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/database/includes/pgpass
	chmod 600 /root/.pgpass
	mkdir -p /var/db/postgres
	chown postgres /var/db/postgres
	service postgresql initdb
	service postgresql start
	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.pgpass
	if ! psql -U postgres -c "CREATE DATABASE ${DB_NAME};"; then
		echo "Failed to create PostgreSQL database, aborting"
		exit 1
	fi
	psql -U postgres -c "CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';"
	psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
	psql -U postgres -c "ALTER DATABASE ${DB_NAME} OWNER to ${DB_USER};"
	psql -U postgres -c "SELECT pg_reload_conf();"
fi

# Save Passwords
echo "${DATABASE_TYPE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${DB_NAME}_db_password.txt
echo "${DB_NAME} database user is ${DB_USER} and password is ${DB_PASSWORD}" >> /root/${DB_NAME}_db_password.txt

echo "---------------"
echo "Installation Complete."
echo "---------------"
echo "Database Information"
echo "$DATABASE_TYPE Username: root"
echo "$DATABASE_TYPE Password: $DB_ROOT_PASSWORD"
echo "$DB_NAME User: $DB_USER"
echo "$DB_NAME Password: "$DB_PASSWORD""
echo "---------------"
echo "All passwords are saved in /root/${DB_NAME}_db_password.txt"
echo "---------------"
