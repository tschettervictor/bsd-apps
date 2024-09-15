#!/bin/sh
# Install MineOS

PYTHON_VERSION="311"
NODE_VERSION="20"
JAVA_VERSION="22"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y git-lite gmake openjdk${JAVA_VERSION} npm-node${NODE_VERSION} node${NODE_VERSION} yarn-node${NODE_VERSION} python${PYTHON_VERSION} py${PYTHON_VERSION}-rdiff-backup py${PYTHON_VERSION}-supervisor rsync screen

# Create Directories
mkdir -p /usr/local/games/
mkdir -p /var/games/minecraft

# Install MineOS
git clone https://github.com/hexparrot/mineos-node /usr/local/games/minecraft
chmod +x /usr/local/games/minecraft/*.sh
chmod +x /usr/local/games/minecraft/*.js
/usr/local/games/minecraft/generate-sslcert.sh
cp /usr/local/games/minecraft/mineos.conf /etc/mineos.conf
cd /usr/local/games/minecraft && yarn add jsegaert/node-userid && npm install
# Uncomment next line to only use http
#sed -i '' "s/^use_https.*/use_https = false/" /etc/mineos.conf
pw useradd -n mineos -u 8443 -G games -d /nonexistent -s /usr/local/bin/bash -h 0 <<EOF
mineos
EOF

# Supervisord Setup
cat /usr/local/games/minecraft/init/supervisor_conf.bsd >> /usr/local/etc/supervisord.conf
sysrc supervisord_enable="YES"
service supervisord start

echo "---------------"
echo "Installation complete."
echo "MineOS is running on port 8443"
echo "---------------"
echo "User Information"
echo "Default user = mineos"
echo "Default password = mineos"
echo "To change the password, use \"passwd mineos\" command."
