#!/bin/sh
# Install SABnzbd

APP_NAME="SABnzbd"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ -f /usr/local/sabnzbd/sabnzbd.ini 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} config detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Install Packages
pkg install -y \
sabnzbd

# Create Directories
mkdir -p /usr/local/sabnzbd

# Enable, Configure and Start Services
sysrc sabnzbd_enable=YES
service sabnzbd start

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 8080."
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "---------------"
fi
