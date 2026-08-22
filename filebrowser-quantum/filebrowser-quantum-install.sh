#!/bin/sh
# Install Filebrowser Quantum

APP_NAME="FileBrowser Quantum"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ -d "/var/db/filebrowser-quantum/filebrowser-quantum.db" ]; then
	echo "Existing ${APP_NAME} data detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Install Packages
pkg install -y \
filebrowser-quantum

# Create Directories
mkdir -p /usr/local/www/filebrowser-quantum
mkdir -p /var/db/filebrowser-quantum
mkdir -p /usr/local/etc/filebrowser-quantum/filebrowser-quantum.yaml
chown -R www:www /usr/local/www/filebrowser-quantum
chown -R www:www /var/db/filebrowser-quantum
chown -R www:www /usr/local/etc/filebrowser-quantum

# App Setup
if [ ! -f "/usr/local/etc/filebrowser-quantum/filebrowser-quantum.yaml" ]; then
    cp -f /usr/local/etc/filebrowser-quantum.yaml /usr/local/etc/filebrowser-quantum/filebrowser-quantum.yaml
fi

# Enable, Configure and Start Services
sysrc filebrowser_quantum_enable=YES
sysrc filebrowser_quantum_config=/usr/local/etc/filebrowser-quantum/filebrowser-quantum.yaml
service filebrowser-quantum start

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 3080."
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "---------------"
fi
