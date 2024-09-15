#!/bin/sh
# Install Jellyfin

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y jellyfin

# Enable and Start Services
sysrc jellyfin_enable=YES
service jellyfin start

echo "---------------"
echo "Installation Complete!"
echo "Jellyfin is running on port 8096"
echo "---------------"
