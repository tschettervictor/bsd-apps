#!/bin/sh
# Install Dasherr

APP_NAME="Dasherr"
APP_VERSION="1.05.02"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y \
caddy

# Create Directories
mkdir -p /usr/local/www/dasherr/www

# Dasherr Setup
fetch -o /tmp/dasherr.zip https://github.com/erohtar/Dasherr/releases/download/v${APP_VERSION}/dasherr.${APP_VERSION}.zip
unzip -u -d /usr/local/www/dasherr /tmp/dasherr.zip

# Enable, Configure and Start Services
fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/dasherr/includes/Caddyfile-nossl
sysrc caddy_enable=YES
sysrc caddy_config=/usr/local/www/Caddyfile
service caddy start

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 80."
echo "---------------"
