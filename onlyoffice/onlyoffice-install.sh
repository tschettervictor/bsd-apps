#!/bin/sh
# Install OnlyOffice Document Server

APP_NAME="OnlyOffice"
DB_TYPE="PostgreSQL"
DB_NAME="onlyoffice"
DB_USER="onlyoffice"
DB_ROOT_PASSWORD=$(openssl rand -base64 15)
DB_PASSWORD=$(openssl rand -base64 15)
RABBITMQ_USER="onlyoffice"
RABBITMQ_PASSWORD=$(openssl rand -base64 15)
JWT_SECRET=$(openssl rand -base64 20)
PG_VERSION="17"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y \
onlyoffice-documentserver \
postgresql"${PG_VERSION}"-client \
postgresql"${PG_VERSION}"-server

# Create and Configure Database
sysrc postgresql_enable="YES"
fetch -o /root/.pgpass https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/onlyoffice/includes/pgpass
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
/usr/local/www/onlyoffice/documentserver/npm/json -q -f /usr/local/etc/onlyoffice/documentserver/local.json -I -e 'this.services.CoAuthoring.sql.dbPass= "'${DB_PASSWORD}'"'
/usr/local/www/onlyoffice/documentserver/npm/json -q -f /usr/local/etc/onlyoffice/documentserver/local.json -I -e 'this.services.CoAuthoring.token.enable.request.inbox= true'
/usr/local/www/onlyoffice/documentserver/npm/json -q -f /usr/local/etc/onlyoffice/documentserver/local.json -I -e 'this.services.CoAuthoring.token.enable.request.outbox= true'
/usr/local/www/onlyoffice/documentserver/npm/json -q -f /usr/local/etc/onlyoffice/documentserver/local.json -I -e 'this.services.CoAuthoring.token.enable.browser= true'

# Add JWT Secret
/usr/local/www/onlyoffice/documentserver/npm/json -q -f /usr/local/etc/onlyoffice/documentserver/local.json -I -e 'this.services.CoAuthoring.secret.inbox.string= "'${JWT_SECRET}'"'
/usr/local/www/onlyoffice/documentserver/npm/json -q -f /usr/local/etc/onlyoffice/documentserver/local.json -I -e 'this.services.CoAuthoring.secret.outbox.string= "'${JWT_SECRET}'"'
/usr/local/www/onlyoffice/documentserver/npm/json -q -f /usr/local/etc/onlyoffice/documentserver/local.json -I -e 'this.services.CoAuthoring.secret.session.string= "'${JWT_SECRET}'"'

# Allow Private IP Connections (needed for local nextcloud instances)
/usr/local/www/onlyoffice/documentserver/npm/json -q -f /usr/local/etc/onlyoffice/documentserver/local.json -I -e 'this.services.CoAuthoring.server={allowPrivateIPAddressForSignedRequests: true }'
/usr/local/www/onlyoffice/documentserver/npm/json -q -f /usr/local/etc/onlyoffice/documentserver/local.json -I -e 'this.services.CoAuthoring.requestDefaults={rejectUnauthorized: false }'
chown onlyoffice:onlyoffice /usr/local/etc/onlyoffice/documentserver/local.json

# Configure RabbitMQ
echo "127.0.0.1 onlyoffice" >> /etc/hosts
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
/usr/local/bin/documentserver-update-securelink.sh
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

# Save Passwords
echo "${DB_TYPE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}-Info.txt
echo "${APP_NAME} database user is ${DB_USER} and password is ${DB_PASSWORD}" >> /root/${APP_NAME}-Info.txt
echo "RabbitMQ user is ${RABBITMQ_USER} and password is ${RABBITMQ_PASSWORD}." >> /root/${APP_NAME}-Info.txt
echo "JWT secret is ${JWT_SECRET}." >> /root/${APP_NAME}-Info.txt

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 80"
echo "---------------"
echo "Database Information"
echo "$DB_TYPE Username: root"
echo "$DB_TYPE Password: $DB_ROOT_PASSWORD"
echo "$APP_NAME DB User: $DB_USER"
echo "$APP_NAME DB Password: $DB_PASSWORD"
echo "RabbitMQ User: $RABBITMQ_USER"
echo "RabbitMQ Password: "$RABBITMQ_PASSWORD""
echo "JWT Secret: "$JWT_SECRET""
echo "---------------"
echo "All passwords are saved in /root/${APP_NAME}-Info.txt"
echo "---------------"
