#!/bin/sh
# Install Immich

APP_NAME="Immich"
DB_TYPE="PostgreSQL"
DB_NAME="immich"
DB_USER="immich"
DB_ROOT_PASSWORD=$(openssl rand -base64 16)
DB_PASSWORD=$(openssl rand -base64 16)
PG_VERSION="18"
TIME_ZONE="America/Edmonton"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Variable Checks
if [ -z "${TIME_ZONE}" ]; then
    echo '[ERROR]: TIME_ZONE must be set'
    exit 1
fi

# Check for Reinstall
if [ "$(ls -A /var/db/immich 2>/dev/null)" ]; then
    echo "Existing ${APP_NAME} data detected. Checking for compatible database..."
   	if [ "$(ls -A /var/db/postgres/data${PG_VERSION} 2>/dev/null)" ]; then
    	  echo "Database looks compatible. Starting reinstall..."
    else
		    echo "ERROR: You cannot continue without the previous database."
   		  echo "Please try again after removing your config files or using the same database used previously."
        exit 1
	  fi
    REINSTALL="true"
fi

# Switch to Latest Repo
mkdir -p /usr/local/etc/pkg/repos
cp /etc/pkg/FreeBSD.conf /usr/local/etc/pkg/repos/
sed -i '' "s/quarterly/latest/" /usr/local/etc/pkg/repos/FreeBSD.conf

# Package Installation
pkg install -y \
immich \
immich-ml \
postgresql"${PG_VERSION}"-contrib \
postgresql"${PG_VERSION}"-pgvector \
postgresql"${PG_VERSION}"-server \
postgresql"${PG_VERSION}"-vchord \
redis

# Create Directories/Users
id -u immich >/dev/null 2>&1 || pw user add immich -c immich -u 2283 -d /nonexistent -s /usr/bin/nologin
mkdir -p /var/db/immich
mkdir -p /var/db/immich-ml
mkdir -p /usr/local/etc
chown -R immich:immich /var/db/immich
chown -R immich:immich /var/db/immich-ml

# Redis Setup
fetch -o /usr/local/etc/redis.conf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/immich/includes/redis.conf
pw usermod immich -G redis
sysrc redis_enable="YES"
service redis start

# Env Setup
if [ ! -f /usr/local/etc/immich.env ]; then
    echo "DB_HOSTNAME=127.0.0.1" > /usr/local/etc/immich.env
    echo "DB_USERNAME=immich" >> /usr/local/etc/immich.env
    echo "DB_DATABASE_NAME=immich" >> /usr/local/etc/immich.env
    echo "DB_PASSWORD=${DB_PASSWORD}" >> /usr/local/etc/immich.env
    echo "REDIS_HOSTNAME=127.0.0.1" >> /usr/local/etc/immich.env
    echo "IMMICH_MACHINE_LEARNING_URL=http://127.0.0.1:3003" >> /usr/local/etc/immich.env
    echo "TZ=${TIME_ZONE}" >> /usr/local/etc/immich.env
else
    sysrc -f /usr/local/etc/immich.env DB_PASSWORD="${DB_PASSWORD}" >/dev/null 2>&1
fi
chown -R immich:immich /usr/local/etc/immich.env

# Database
sysrc postgresql_enable="YES"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, but the ${DB_TYPE} root password AND ${APP_NAME} database password will be changed."
 	echo "New passwords will be saved in the root directory."
 	psql -U postgres -c "ALTER USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"
 	fetch -o /root/.pgpass https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/immich/includes/pgpass
  	chmod 600 /root/.pgpass
   	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.pgpass
    service postgresql start
else
    fetch -o /root/.pgpass https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/immich/includes/pgpass
    chmod 600 /root/.pgpass
    sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.pgpass
    service postgresql initdb
    service postgresql start
    if ! psql -U postgres -c "CREATE DATABASE ${DB_NAME}"; then
		    echo "Failed to create ${APP_NAME} database, aborting"
		    exit 1
	  fi
	  sed -i '' "s/^#shared_preload_libraries = .*/shared_preload_libraries = \'vchord.so\'/" /var/db/postgres/data"${PG_VERSION}"/postgresql.conf
	  service postgresql restart
      psql -U postgres -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS vector;"
      psql -U postgres -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS vchord CASCADE;"
      psql -U postgres -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS cube;"
      psql -U postgres -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS earthdistance;"
      psql -U postgres -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
	  psql -U postgres -c "CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASSWORD}';"
	  psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
      psql -U postgres -c "GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};"
	  psql -U postgres -c "ALTER DATABASE ${DB_NAME} OWNER TO ${DB_USER};"
	  psql -U postgres -c "SELECT pg_reload_conf();"
fi

# Services
sysrc immich_ml_enable=YES
sysrc immich_server_enable=YES
service postgresql restart
service redis restart
service immich_ml start
service immich_server start

# Save Passwords
echo "${DB_TYPE} root password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}-Info.txt
echo "${APP_NAME} database password is ${DB_PASSWORD}" >> /root/${APP_NAME}-Info.txt

# Done
echo "---------------"
echo "Installation complete."
echo "---------------"
echo "Database Information"
echo "$DB_TYPE Username: root"
echo "$DB_TYPE Password: $DB_ROOT_PASSWORD"
echo "$APP_NAME DB User: $DB_USER"
echo "$APP_NAME DB Password: $DB_PASSWORD"
echo "--------------------"
echo "All passwords are saved in /root/${APP_NAME}-Info.txt"
echo "---------------"
echo "${APP_NAME} is running on port 2283."
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "---------------"
else
    echo "Visit the ${APP_NAME} WebUI to start setup."
	echo "---------------"
fi
