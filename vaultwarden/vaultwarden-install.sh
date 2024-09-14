#!/bin/sh
# Install Vaultwarden

APP_NAME="vaultwarden"
PYTHON_VERSION="311"
ADMIN_TOKEN=$(openssl rand -base64 16)

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ "$(ls -A "/usr/local/www/vaultwarden/data" 2>/dev/null)" ]; then
	echo "Existing Vaultwarden data detected..."
	REINSTALL="true"
fi

# Install Packages
pkg install -y vaultwarden git-lite py${PYTHON_VERSION}-argon2-cffi bash

# Create Directories
mkdir -p /usr/local/etc/rc.conf.d

# Fetch Vaultwarden File
fetch -o /usr/local/etc/rc.conf.d/vaultwarden https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/vaultwarden/includes/vaultwarden

# Generate Secure Token/Hash Using argon2
if [ "${REINSTALL}" == "true" ]; then
	echo "Admin token will not be changed on a reinstall."
 	echo "Consult the docs to manually change it if needed."
else
	ADMIN_HASH=$(echo -n ${ADMIN_TOKEN} | argon2 $(openssl rand -base64 32) -e -id -k 65540 -t 3 -p 4)
	sed -i '' "s|youradmintokenhere|${ADMIN_HASH}|" /usr/local/etc/rc.conf.d/vaultwarden
fi

# Enable and Start Services
sysrc vaultwarden_enable="YES"
service vaultwarden start

# Save Passwords for Later Reference
echo "Your admin token to access the admin portal is ${ADMIN_TOKEN}" > /root/${APP_NAME}_admin_token.txt

echo "---------------"
echo "Installation complete."
echo "Vaultwarden is running on port 4567"
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, your admin token has not changed."
 	echo "If you need to generate a new one, please see the vaultwarden github."
else
 	echo "Admin Portal Information"
 	echo "Your admin token to access the admin portal is ${ADMIN_TOKEN}"
  	echo "---------------"
	echo "The admin token is saved in /root/${APP_NAME}_admin_token.txt"
fi
