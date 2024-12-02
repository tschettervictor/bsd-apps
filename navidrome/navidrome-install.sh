#!/bin/sh
# Install Navidrome

APP_NAME="Navidrome"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ "$(ls -d /usr/local/etc/navidrome 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} config detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Install Packages
pkg install -y \
navidrome

# Create Directories
mkdir -p /usr/local/share/navidrome/music
mkdir -p /usr/local/etc/navidrome
mkdir -p /var/db/navidrome

# Enable, Configure and Start Services
sysrc navidrome_enable=YES
sysrc navidrome_config="/usr/local/etc/navidrome/config.toml"
sysrc navidrome_flags="--address 0.0.0.0"
service navidrome start

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 4533."
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "---------------"
fi
