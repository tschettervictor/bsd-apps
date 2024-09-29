#!/bin/sh
# Install Uptime-Kuma

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

DATA_PATH="/mnt/data"
NODE_VERSION="18"

# Install Packages
pkg install -y git-lite npm-node"${NODE_VERSION}"

# Create Directories
mkdir -p "${DATA_PATH}"
mkdir -p /usr/local/etc/rc.d
mkdir -p /var/run/uptimekuma

# Uptime-Kuma Setup
pw user add uptimekuma -c uptimekuma -u 3001 -d /nonexistent -s /usr/bin/nologin
npm install npm -g
cd /usr/local/ && git clone https://github.com/louislam/uptime-kuma.git
cd /usr/local/uptime-kuma && npm run setup
sed -i '' "s|console.log(\"Welcome to Uptime Kuma\");|process.chdir('/usr/local/uptime-kuma');\n&|" /usr/local/uptime-kuma/server/server.js
fetch -o /usr/local/etc/rc.d/ https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/uptime-kuma/includes/uptimekuma
chmod +x /usr/local/etc/rc.d/uptimekuma
chown -R uptimekuma:uptimekuma /var/run/uptimekuma
chown -R uptimekuma:uptimekuma /usr/local/uptime-kuma
chown -R uptimekuma:uptimekuma "${DATA_PATH}"

# Enable and Start Services
sysrc uptimekuma_enable="YES"
sysrc uptimekuma_datadir="${DATA_PATH}"
service uptimekuma start

# Done
echo "---------------"
echo "Installation Complete!"
echo "Uptime-Kuma is running on port 3001"
echo "---------------"
