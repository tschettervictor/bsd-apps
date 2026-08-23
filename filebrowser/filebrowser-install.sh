#!/bin/sh
# Install FileBrowser

APP_NAME="FileBrowser"

# Check for Root Privileges
if ! [ "$(id -u)" = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ -d "/var/db/filebrowser/filebrowser.db" ]; then
	echo "Existing ${APP_NAME} data detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Install Packages
pkg install -y \
filebrowser

# Create Directories
mkdir -p /usr/local/www/filebrowser
mkdir -p /var/db/filebrowser
chown -R filebrowser:filebrowser /usr/local/www/filebrowser
chown -R filebrowser:filebrowser /var/db/filebrowser

# Enable, Configure and Start Services
sysrc filebrowser_enable=YES
service filebrowser start

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 8080."
echo "---------------"
if [ "${REINSTALL}" = "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "---------------"
fi
