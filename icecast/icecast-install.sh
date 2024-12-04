#!/bin/sh
# Install Icecast

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y \
icecast

# Create Directories
mkdir -p /usr/local/etc/icecast
mkdir -p /var/log/icecast

# Icecast Setup
if [ ! -f /usr/local/etc/icecast/icecast.xml ]; then
   cp /usr/local/etc/icecast.xml /usr/local/etc/icecast/
fi

# Enable and Start Services
sysrc icecast_config="/usr/local/etc/icecast/icecast.xml"
sysrc icecast_enable="YES"
service icecast start

# Done
echo "---------------"
echo "Installation Complete!"
echo "---------------"
echo "Icecast will not run as root. Change the user to "www" or some other user at the end of the icecast.xml file."
echo "Don't forget to uncomment the "changeowner" section, and change the owner of "/var/log/icecast" to the user that icecast will run as."
echo "---------------"
