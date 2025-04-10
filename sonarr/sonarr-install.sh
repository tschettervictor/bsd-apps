#!/bin/sh
# Install Sonarr

APP_NAME="Sonarr"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ "$(ls -d /usr/local/sonarr 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} data detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Install Packages
pkg install -y \
sonarr

# Create Directories
mkdir -p /usr/local/sonarr

# Enable, Configure and Start Services
sysrc sonarr_enable=YES
service sonarr start

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 8989."
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "---------------"
fi
