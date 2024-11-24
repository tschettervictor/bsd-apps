#!/bin/sh
# Install Grafana

APP_NAME="Grafana"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y \
grafana

# Enable and Start Services
sysrc grafana_enable="YES"
service grafana start

# Done
echo "---------------"
echo "Installation complete."
echo "$APP_NAME is running on port 32400"
echo "Default user is admin and password is admin."
echo "---------------"
