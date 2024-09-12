#!/bin/sh
# Install Rustdesk Server

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install packages
pkg install -y rustdesk-server

# Enable services
sysrc rustdesk_hbbr_enable=YES
sysrc rustdesk_hbbs_enable=YES

# Start services
service rustdesk-hbbr start
service ristdesk-hbbs start

echo "---------------"
echo "Installation Complete!"
echo "---------------"
