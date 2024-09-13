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
mkdir -p /var/run/uptimekuma/

# Install Uptime-Kuma
if [ "$(ls -A "/mnt/data")" ]; then
   echo "Existing Uptime-Kuma data detected..."
   REINSTALL=1
fi
pw user add uptimekuma -c uptimekuma -u 3001 -d /nonexistent -s /usr/bin/nologin
npm install npm -g
cd /usr/local/ && git clone https://github.com/louislam/uptime-kuma.git
cd /usr/local/uptime-kuma && npm run setup
sed -i '' "s|console.log(\"Welcome to Uptime Kuma\");|process.chdir('/usr/local/uptime-kuma');\n&|" /usr/local/uptime-kuma/server/server.js
fetch -o /usr/local/etc/rc.d/ https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/uptime-kuma/usr/local/etc/rc.d/uptimekuma
if [ "${REINSTALL}" != "1" ]; then
   cp -r /usr/local/uptime-kuma/data* /mnt/data
fi
rm -r /usr/local/uptime-kuma/data

# Change directory ownership
chown -R uptimekuma:uptimekuma /var/run/uptimekuma
chown -R uptimekuma:uptimekuma /mnt/data
chown -R uptimekuma:uptimekuma /usr/local/uptime-kuma

# Enable and start services
sysrc uptimekuma_enable="YES"
service uptimekuma start

echo "---------------"
echo "Installation Complete!"
echo "---------------"
