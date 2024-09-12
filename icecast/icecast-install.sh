#!/bin/sh
# Install Icecast

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install packages
pkg install -y icecast

# Create directories and copy config file
mkdir -p /usr/local/www/icecast
mkdir -p /var/log/icecast
cp /usr/local/etc/icecast.xml /usr/local/www/icecast/

# Enable and start services
sysrc icecast_config="/usr/local/www/icecast/icecast.xml"
sysrc icecast_enable="YES"
service icecast start

echo "---------------"
echo "Installation Complete!"
echo "---------------"
echo "Icecast will not run as root. Change the user to "www" or some other user at the end of the icecast.xml file."
echo "Don't forget to uncomment the "changeowner" section, and change the owner of "/var/log/icecast" to the user that icecast will run as."
echo "---------------"
