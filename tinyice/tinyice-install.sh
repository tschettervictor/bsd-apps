#!/bin/sh
# Install Tinyice

APP_NAME="TinyIce"
NODE_VERSION="20"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y \
node"${NODE_VERSION}" \
git-lite \
go

# Create Directories
mkdir -p /usr/local/etc/tinyice
mkdir -p /usr/local/etc/rc.d
mkdir -p /var/run/tinyice
mkdir -p /var/log/tinyice
chown -R tinyice:tinyice /usr/local/tinyice
chown -R tinyice:tinyice /var/log/tinyice
chown -R tinyice:tinyice /var/run/tinyice

# TinyIce Setup
id -u tinyice 2>&1 || pw user add tinyice -c tinyice -u 8000 -d /nonexistent -s /usr/bin/nologin
git clone https://github.com/DatanoiseTV/tinyice /usr/local/tinyice
cd /usr/local/tinyice && make build
cp -f /usr/local/tinyice/tinyice /usr/local/bin/tinyice
rm -rf /usr/local/tinyice
chmod +x /usr/local/bin/tinyice
fetch -o /usr/local/etc/rc.d/tinyice https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/tinyice/includes/tinyice
chmod +x /usr/local/etc/rc.d/tinyice

# Enable and Start Services
sysrc tinyice_enable="YES"
service tinyice start

echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 8000"
echo "---------------"
echo "Not the 'Setup Token' that was just shown."
ehco "You will need it when first visiting TinyIce."
echo "If you missed it, just remove the config file, and restart the service."
echo "---------------"
