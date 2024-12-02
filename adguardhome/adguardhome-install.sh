#!/bin/sh
# Install AdGuardHome

APP_NAME="AdGuardHome"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ -d /var/db/adguardhome ]; then
	echo "Existing ${APP_NAME} data detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Install Packages
pkg install -y \
adguardhome

# Create Directories
mkdir -p /usr/local/etc/adguardhome
mkdir -p /var/db/adguardhome

# Enable, Configure and Start Services
sysrc adguardhome_enable=YES
if [ ! -f /usr/local/etc/adguardhome/AdGuardHome.yaml ]; then
  cp /usr/local/etc/AdGuardHome.yaml /usr/local/etc/adguardhome/
fi
sysrc adguardhome_config="/usr/local/etc/adguardhome/AdGuardHome.yaml"
service adguardhome start

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 3000."
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "If you changed the default port initially, visit ${APP_NAME} on that port."
	echo "---------------"
fi
