#!/bin/sh
# Install Tinyice

APP_NAME="TinyIce"
NODE_VERSION="20"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ -f "/usr/local/etc/tinyice/tinyice.json" ]; then
	echo "Existing ${APP_NAME} config detected."
   echo "Starting reinstall..."
	REINSTALL="true"
fi

# Install Packages
pkg install -y \
node"${NODE_VERSION}" \
npm-node"${NODE_VERSION}" \
git-lite \
go

# Directory Setup
id -u tinyice >/dev/null 2>&1 || pw user add tinyice -c tinyice -u 8000 -d /nonexistent -s /usr/bin/nologin
mkdir -p /usr/local/etc/tinyice
mkdir -p /usr/local/etc/rc.d
mkdir -p /var/run/tinyice
mkdir -p /var/log/tinyice
chown -R tinyice:tinyice /usr/local/etc/tinyice
chown -R tinyice:tinyice /var/log/tinyice
chown -R tinyice:tinyice /var/run/tinyice

# TinyIce Setup
if [ "${REINSTALL}" = "true" ]; then
   service tinyice onestop >/dev/null 2>&1
   rm -rf /usr/local/tinyice
fi
git clone https://github.com/DatanoiseTV/tinyice /usr/local/tinyice
cd /usr/local/tinyice && make build
cp -f /usr/local/tinyice/tinyice /usr/local/bin/tinyice
chmod +x /usr/local/bin/tinyice
fetch -o /usr/local/etc/rc.d/tinyice https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/tinyice/includes/tinyice
chmod +x /usr/local/etc/rc.d/tinyice

# Enable and Start Services
sysrc tinyice_enable="YES"
service tinyice start

# Save Passwords
if [ "${REINSTALL}" != "true" ]; then
    SETUP_TOKEN="$(grep 'Setup Token:' /var/log/tinyice/tinyice.log | awk -F': ' '{print $2}')"
    echo "${APP_NAME} setup token for first run is: ${SETUP_TOKEN}" > /root/${APP_NAME}-Info.txt
fi

echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 8000"
echo "---------------"
if [ "${REINSTALL}" != "true" ]; then
    echo "Setup Information"
    echo "Setup Token: ${SETUP_TOKEN}"
    echo "---------------"
    echo "You will need the Setup Token when running TinyIce for the first time."
    echo "If you missed it, check /root/${APP_NAME}-Info.txt."
    echo "---------------"
fi
