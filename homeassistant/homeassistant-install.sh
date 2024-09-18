#!/bin/sh
# Install Homeassistant Core

PYTHON_VERSION="311"
PYTHON_BINARY="3.11"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y bash autoconf ca_root_nss curl ffmpeg gcc gmake libjpeg-turbo libxml2 libxslt pkgconf python${PYTHON_VERSION} py${PYTHON_VERSION}-numpy py${PYTHON_VERSION}-sqlite3 py${PYTHON_VERSION}-wheel py${PYTHON_VERSION}-setuptools py${PYTHON_VERSION}-installer rust sudo zlib-ng zip

# Create Directories
mkdir -p /home/homeassistant/config
mkdir -p /usr/local/etc/rc.d
mkdir -p /mnt/includes
mkdir -p /usr/local/www

# Install Homeassistant
install -d -g 8123 -o 8123 -m 775 -- /home/homeassistant
pw adduser -u 8123 -n homeassistant -d /home/homeassistant -w no -s /usr/local/bin/bash -G dialer
chown -R homeassistant:homeassistant /home/homeassistant
fetch -o /usr/local/etc/rc.d/homeassistant https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/homeassistant/includes/homeassistant
chmod +x /usr/local/etc/rc.d/homeassistant
sysrc homeassistant_python=/usr/local/bin/python${PYTHON_BINARY}
sysrc homeassistant_venv=/usr/local/share/homeassistant
sysrc homeassistant_user=homeassistant
sysrc homeassistant_config_dir=/home/homeassistant/config
sysrc homeassistant_enable=yes
service homeassistant install homeassistant    
service homeassistant start homeassistant

echo "---------------"
echo "Installation complete!"
echo "---------------"
echo "It will take 5-10 minutes to fully start homeassistant the first time."
echo "Please also allow some additional time to configure extra packages."
