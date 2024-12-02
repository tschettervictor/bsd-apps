#!/bin/sh
# Install Grafana

APP_NAME="Grafana"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ "$(ls -A /usr/local/share/grafana 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} data detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Install Packages
pkg install -y \
grafana

# Enable and Start Services
sysrc grafana_enable="YES"
service grafana start

# Done
echo "---------------"
echo "Installation complete."
echo "$APP_NAME is running on port 32400"
echo "Default user is admin and password is admin."
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "---------------"
else
	echo "User Information"
	echo "Default ${APP_NAME} user is admin"
	echo "Default ${APP_NAME} password is admin"
	echo "---------------"
fi
