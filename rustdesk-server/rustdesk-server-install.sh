#!/bin/sh
# Install Rustdesk Server

SERVER=""

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y \
rustdesk-server

# Enable and Start Services
sysrc rustdesk_hbbr_enable=YES
sysrc rustdesk_hbbs_enable=YES
sysrc rustdesk_hbbs_ip="${SERVER}"
service rustdesk-hbbr start
service rustdesk-hbbs start

# Done
echo "---------------"
echo "Installation Complete!"
echo "---------------"
