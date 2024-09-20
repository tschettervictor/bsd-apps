#!/bin/sh
# Install OnlyOffice Document Server

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

APP_NAME="onlyoffice"
PG_VERSION="15"
DATABASE="postgres"
DB_NAME="onlyoffice"
DB_USER="onlyoffice"
DB_ROOT_PASSWORD=$(openssl rand -base64 15)
DB_PASSWORD=$(openssl rand -base64 15)
RABBITMQ_USER="onlyoffice"
RABBITMQ_PASSWORD=$(openssl rand -base64 15)

# Install Packages
pkg install -y onlyoffice-documentserver postgresql"${PG_VERSION}"-server postgresql"${PG_VERSION}"-client

# Create and Configure Database
sysrc postgresql_enable="YES"
fetch -o /root/.pgpass https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/onlyoffice-documentserver/includes/pgpass
chmod 600 /root/.pgpass
mkdir -p /var/db/postgres
chown postgres /var/db/postgres/
service postgresql initdb
service postgresql start
sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.pgpass
psql -U postgres -c "CREATE DATABASE ${DB_NAME};"
psql -U postgres -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};"
psql -U postgres -c "ALTER DATABASE ${DB_NAME} OWNER to ${DB_USER};"
psql -hlocalhost -U${DB_USER} -d ${DB_NAME} -f /usr/local/www/onlyoffice/documentserver/server/schema/postgresql/createdb.sql
psql -U postgres -c "SELECT pg_reload_conf();"

# Configure OnlyOffice Config File
sed -i '' "/dbPass/s|onlyoffice|${DB_PASSWORD}|" /usr/local/etc/onlyoffice/documentserver/local.json
sed -i '' "1,/inbox/s|false|true|" /usr/local/etc/onlyoffice/documentserver/local.json
sed -i '' "1,/outbox/s|false|true|" /usr/local/etc/onlyoffice/documentserver/local.json
sed -i '' "1,/browser/s|false|true|" /usr/local/etc/onlyoffice/documentserver/local.json
sed -i '' "1,/rejectUnauthorized/s|true|false|" /usr/local/etc/onlyoffice/documentserver/default.json

# Allow Private IP Connections (needed for local nextcloud instances)
/usr/local/www/onlyoffice/documentserver/npm/json -q -f /usr/local/etc/onlyoffice/documentserver/local.json -I -e 'this.services.CoAuthoring.server={allowPrivateIPAddressForSignedRequests: true }'
chown onlyoffice:onlyoffice /usr/local/etc/onlyoffice/documentserver/local.json

# Configure RabbitMQ
sysrc rabbitmq_enable="YES"
service rabbitmq start
rabbitmqctl --erlang-cookie $(cat /var/db/rabbitmq/.erlang.cookie) add_user ${RABBITMQ_USER} ${RABBITMQ_PASSWORD}
rabbitmqctl --erlang-cookie $(cat /var/db/rabbitmq/.erlang.cookie) set_user_tags ${RABBITMQ_USER} administrator
rabbitmqctl --erlang-cookie $(cat /var/db/rabbitmq/.erlang.cookie) set_permissions -p / ${RABBITMQ_USER} ".*" ".*" ".*"
sed -i '' -e "s|guest:guest@localhost|${RABBITMQ_USER}:${RABBITMQ_PASSWORD}@localhost|g" /usr/local/etc/onlyoffice/documentserver/local.json
chown onlyoffice:onlyoffice /usr/local/etc/onlyoffice/documentserver/local.json

# Configure Nginx
sysrc nginx_enable="YES"
mkdir -p /usr/local/etc/nginx/conf.d
cp /usr/local/etc/onlyoffice/documentserver/nginx/ds.conf /usr/local/etc/nginx/conf.d/.
sed -i '' -e '40s/^/    include \/usr\/local\/etc\/nginx\/conf.d\/*.conf;\n/g' /usr/local/etc/nginx/nginx.conf
sed -i '' '4d' /usr/local/etc/nginx/conf.d/ds.conf
service nginx start

# Configure Supervisord
sysrc supervisord_enable="YES"
echo '[include]' >> /usr/local/etc/supervisord.conf
echo 'files = /usr/local/etc/onlyoffice/documentserver/supervisor/*.conf' >> /usr/local/etc/supervisord.conf
sed -i "" -e 's|/tmp/supervisor.sock|/var/run/supervisor/supervisor.sock|g' /usr/local/etc/supervisord.conf
/usr/local/bin/documentserver-pluginsmanager.sh --update=/usr/local/www/onlyoffice/documentserver/sdkjs-plugins/plugin-list-default.json

# Restart Services
service nginx restart
service rabbitmq restart
service supervisord restart
supervisorctl start all

# Save Passwords/Finalize Installation
echo "${DATABASE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}_db_password.txt
echo "OnlyOffice database user is ${DB_USER} and password is ${DB_PASSWORD}" >> /root/${APP_NAME}_db_password.txt
echo "RabbitMQ user is ${RABBITMQ_USER} and password is ${RABBITMQ_PASSWORD}." >> /root/${APP_NAME}_db_password.txt

echo "---------------"
echo "Installation complete."
echo "---------------"
echo "Database Information"
echo "MySQL Username: root"
echo "MySQL Password: $DB_ROOT_PASSWORD"
echo "RabbitMQ User: $RABBITMQ_USER"
echo "RabbitMQ Password: "$RABBITMQ_PASSWORD""
echo "---------------"
echo "All passwords are saved in /root/${APP_NAME}_db_password.txt"
echo "---------------"
