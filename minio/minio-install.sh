#!/bin/sh
# Install Minio

APP_NAME="Minio"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ "$(ls -d /var/db/minio/.minio.sys/config 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} data detected."
	echo "Starting reinstall..."
	REINSTALL="true"
fi

# Install Packages
pkg install -y \
minio

# Create Directories
mkdir -p /var/db/minio
chown -R minio:minio /var/db/minio
mkdir -p /usr/local/etc/minio
chown -R minio:minio /usr/local/etc/minio

# Enable, Configure and Start Services
sysrc minio_enable=YES
service minio start

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 9000."
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall."
 	echo "Please user your old credentials to log in."
	echo "---------------"
else
	echo "User Information"
	echo "Default ${APP_NAME} user is minioadmin"
	echo "Default ${APP_NAME} password is minioadmin"
	echo "---------------"
fi
