#!/bin/sh
# Install Uptime-Kuma

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

NODE_VERSION="18"

# Install packages
pkg install -y git-lite npm-node${NODE_VERSION}

# Create directories
mkdir -p /mnt/data
mkdir -p /usr/local/etc/rc.d/
mkdir -p /var/run/uptime-kuma/

# Install Uptime-Kuma
pw user add uptime-kuma -c uptime-kuma -u 3001 -d /nonexistent -s /usr/bin/nologin
npm install npm -g
cd /usr/local/ && git clone https://github.com/louislam/uptime-kuma.git
cd /usr/local/uptime-kuma && npm run setup
sed -i '' "s|console.log(\"Welcome to Uptime Kuma\");|process.chdir('/usr/local/uptime-kuma');\n&|" /usr/local/uptime-kuma/server/server.js
fetch https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/uptime-kuma/usr/local/etc/rc.d/uptime-kuma /usr/local/etc/rc.d/
chown -R uptime-kuma:uptime-kuma /usr/local/uptime-kuma
chown -R uptime-kuma:uptime-kuma /var/run/uptime-kuma

# Enable and start services
sysrc uptime_kuma_enable="YES"
service uptime-kuma start

echo "---------------"
echo "Installation Complete!"
echo "---------------"
