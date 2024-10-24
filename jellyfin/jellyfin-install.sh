#!/bin/sh
# Install Jellyfin

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y \
jellyfin

# Create Directories
mkdir -p /var/db/jellyfin
chown -R jellyfin:jellyfin /var/db/jellyfin

# Enable and Start Services
sysrc jellyfin_enable=YES
service jellyfin start

# Done
echo "---------------"
echo "Installation Complete!"
echo "Jellyfin is running on port 8096"
echo "---------------"
