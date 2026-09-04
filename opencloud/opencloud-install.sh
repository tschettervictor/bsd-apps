#!/bin/sh
# Install OpenCloud

APP_NAME="OpenCloud"
APP_VERSION="latest"
APP_HTTP_MODE="https"
ADMIN_PASSWORD="$(openssl rand -base64 12)"
DATA_PATH="/mnt/data"
NODE_VERSION="24"
HOST_NAME=""

# Check for Root Privileges
if ! [ "$(id -u)" = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Variable Checks
if [ -z "${HOST_NAME}" ]; then
  echo 'Configuration error: HOST_NAME must be set'
  exit 1
fi

# Packages
pkg install -y \
bash \
git-tiny \
gmake \
go \
node"${NODE_VERSION}" \
npm-node"${NODE_VERSION}"

# Check for reinstall
if [ -d "${DATA_PATH}/opencloud/data" ]; then
    REINSTALL="true"
fi

# Directories/Files
mkdir -p "${DATA_PATH}"/opencloud/data
mkdir -p /usr/local/etc/opencloud
mkdir -p /usr/local/etc/rc.d
touch /usr/local/etc/opencloud/.env
chown -R www:www "${DATA_PATH}"
chown -R www:www /usr/local/etc/opencloud

# OpenCloud
npm install -g corepack@latest
corepack enable pnpm
if [ "${APP_VERSION}" = "latest" ]; then
    git clone https://github.com/opencloud-eu/opencloud /tmp/"${APP_NAME}"
else
    fetch -o /tmp/"${APP_NAME}".tar.gz https://github.com/opencloud-eu/opencloud/archive/refs/tags/v"${APP_VERSION}".tar.gz
    mkdir -p /tmp/"${APP_NAME}"
    tar -xv -f /tmp/"${APP_NAME}".tar.gz --strip-components=1 -C /tmp/"${APP_NAME}"
fi
fetch -o /tmp/patch https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/opencloud/includes/patch
cd /tmp/"${APP_NAME}" && patch < /tmp/patch
EDITION="rolling" \
cd /tmp/"${APP_NAME}" && gmake clean generate VERSION="${APP_VERSION}"
COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
EDITION="rolling" \
cd /tmp/"${APP_NAME}" && gmake -C opencloud build VERSION="${APP_VERSION}"
cp -f /tmp/"${APP_NAME}"/opencloud/bin/opencloud /usr/local/bin/opencloud
rm -r /tmp/"${APP_NAME}"*
rm -r /tmp/patch
if [ "${REINSTALL}" != "true" ]; then
    if [ "${APP_HTTP_MODE}" = "http" ]; then
        echo "OC_INSECURE=true" >> /usr/local/etc/opencloud/.env
        echo "OC_URL=http://${HOST_NAME}:9200" >> /usr/local/etc/opencloud/.env
    else
        echo "OC_URL=https://${HOST_NAME}:9200" >> /usr/local/etc/opencloud/.env
    fi
    OC_BASE_DATA_PATH="${DATA_PATH}/opencloud" \
    OC_CONFIG_DIR="/usr/local/etc/opencloud" \
    /usr/local/bin/opencloud init --insecure true --admin-password "${ADMIN_PASSWORD}"
fi
chown -R www:www "${DATA_PATH}"
chown -R www:www /usr/local/etc/opencloud

# Services
fetch -o /usr/local/etc/rc.d https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/opencloud/includes/opencloud
chmod +x /usr/local/etc/rc.d/opencloud
sysrc opencloud_datadir="${DATA_PATH}/opencloud/data"
sysrc opencloud_configdir="/usr/local/etc/opencloud"
sysrc opencloud_enable="YES"
service opencloud start

# Done
echo "---------------"
echo "Installation Complete!"
echo "${APP_NAME} is running on port 9200"
echo "---------------"
