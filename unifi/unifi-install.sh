#!/bin/sh
# Install Unifi Controller

APP_NAME="Unifi"
UNIFI_VERSION="8"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y \
unifi${UNIFI_VERSION}

# Enable and Start Services
sysrc unifi_enable=YES
sysrc mondod_enable=yes
service mondod start
service unifi start

# Done
echo "---------------"
echo "Installation Complete."
echo "${APP_NAME} is running on port 8443"
echo "---------------"
