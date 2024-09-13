#!/bin/sh
# Install MeshCentral

NODE_VERSION="20"

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install packages
pkg install -y npm-node"${NODE_VERSION}" node"${NODE_VERSION}"

# Create directories
mkdir -p /usr/local/meshcentral/meshcentral-data
mkdir -p /usr/local/meshcentral/meshcentral-files
mkdir -p /usr/local/meshcentral/meshcentral-backups
mkdir -p /usr/local/etc/rc.d
mkdir -p /var/run/meshcentral

# Install MeshCentral
pw user add meshcentral -c meshcentral -u 6374 -s /usr/sbin/nologin -d /home/meshcentral -m
cd /usr/local/meshcentral && npm install meshcentral
chown -R meshcentral:meshcentral /usr/local/meshcentral
chown -R meshcentral:meshcentral /var/run/meshcentral
fetch -o /usr/local/etc/rc.d/ https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/meshcentral/usr/local/etc/rc.d/meshcentral

# Enable and start services
sysrc meshcentral_enable="YES"
service meshcentral start && sleep 5

echo "---------------"
echo "Installation complete."
echo "MeshCentral is running on port 1025"
echo "---------------"
