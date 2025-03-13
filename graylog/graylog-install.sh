#!/bin/sh
# Install Graylog

APP_NAME="Graylog"
ADMIN_PASSWORD="graylog"
ADMIN_PASSWORD_HASH="$(echo -n ${ADMIN_PASSWORD} | sha256)"
MONGODB_VERSION="60"
PASSWORD_SECRET="$(openssl rand -base64 128 | tr -dc 'A-Za-z0-9' | head -c 96)"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Package Installation
pkg install -y \
elasticsearch7 \
graylog \
mongodb${MONGODB_VERSION}

# Create Directories
mkdir -p /usr/local/etc/graylog/server
mkdir -p /usr/local/share/graylog/journal
touch /usr/local/etc/graylog/server/node-id
chown -R graylog:graylog /usr/local/etc/graylog
chown -R graylog:graylog /usr/local/share/graylog

# Elasticsearch Setup
sed -i '' 's/\#cluster\.name\:\ my\-application/cluster\.name\:\ graylog/g' /usr/local/etc/elasticsearch/elasticsearch.yml
sed -i '' 's/\#node\.name\:\ node\-1/node\.name\:\ node\-1/g' /usr/local/etc/elasticsearch/elasticsearch.yml
sed -i '' 's/\#network\.host\:.*/network\.host\:\ 127\.0\.0\.1/g' /usr/local/etc/elasticsearch/elasticsearch.yml
sed -i '' 's/\#cluster\.initial\_master\_nodes\:.*/cluster\.initial\_master\_nodes\:\ \[\"node\-1\"\]/g' /usr/local/etc/elasticsearch/elasticsearch.yml

# Graylog Setup
sed -i '' 's/node\_id\_file\ \=\ \/etc\/graylog\/server\/node-id/node\_id\_file\ \=\ \/usr\/\local\/etc\/graylog\/server\/node-id/g' /usr/local/etc/graylog/graylog.conf
sed -i '' 's/bin\_dir\ \=\ bin/\bin\_dir\ \=\ \/usr\/local\/share\/graylog/g' /usr/local/etc/graylog/graylog.conf
sed -i '' 's/plugin\_dir\ \=\ plugin/\plugin\_dir\ \=\ \/usr\/local\/share\/graylog\/plugin/g' /usr/local/etc/graylog/graylog.conf
sed -i '' 's/data\_dir\ \=\ data/\data\_dir\ \=\ \/usr\/local\/share\/graylog/g' /usr/local/etc/graylog/graylog.conf
sed -i -e "s/\#http\_bind\_address\ \=\ 127\.0\.0\.1\:9000/http\_bind\_address\ \= 0\.0\.0\.0\:9000/g" /usr/local/etc/graylog/graylog.conf
sed -i '' 's/message\_journal\_dir\ \=\ data\/journal/message\_journal\_dir\ \=\ \/usr\/local\/share\/graylog\/journal/g' /usr/local/etc/graylog/graylog.conf
sed -i -e "s/password\_secret\ \=/password\_secret\ \=\ ${PASSWORD_SECRET}/g" /usr/local/etc/graylog/graylog.conf
sed -i -e "s/root\_password\_sha2\ \=/root\_password\_sha2\ \=\ ${ADMIN_PASSWORD_HASH}/g" /usr/local/etc/graylog/graylog.conf

# Enable and Start Services
sysrc elasticsearch_enable="YES"
sysrc mongod_enable="YES"
sysrc graylog_enable="YES"
service elasticsearch start
service mongod start
service graylog start

# Retrieve Initial Configuration Details
wait 10
CONFIG_DETAILS="$(cat /var/log/graylog/server.log | grep -m 1 "Initial configuration")"

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 9000."
echo "---------------"
echo "User Information"
echo "Default ${APP_NAME} user is admin"
echo "Default ${APP_NAME} password is ${ADMIN_PASSWORD}"
echo "---------------"
echo "Before logging into graylog, you must complete an initial configuration."
echo "If you are using a multi-node setup, complete the full setup."
echo "If not, only the first two steps are necessary, then select \"Skip provisioning\" to complete the setup."
echo "---------------"
echo "Configuration Page Info"
echo "${CONFIG_DETAILS}"
echo "---------------"
