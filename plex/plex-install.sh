#!/bin/sh
# Install Plex Media Server

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

BETA="0"

# Install Packages
if [ ${BETA} -eq 1 ]; then
	pkg install -y plexmediaserver-plexpass
else
	pkg install -y plexmediaserver
fi

# Create Directories and Switch to Latest Repo
mkdir -p /mnt/plex-data
chown -R 972:972 /mnt/plex-data
mkdir -p /usr/local/etc/pkg/repos
cp /etc/pkg/FreeBSD.conf /usr/local/etc/pkg/repos/
sed -i '' "s/quarterly/latest/" /usr/local/etc/pkg/repos/FreeBSD.conf

# Enable Daily Package Updates
if [ ${BETA} -eq 1 ]; then
	fetch -o /tmp/update_packages https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/plex/includes/update_packages.cron.beta
else
	fetch -o /tmp/update_packages https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/plex/includes/update_packages.cron
fi
crontab /tmp/update_packages
rm /tmp/update_packages

# Enable and Start Services
if [ ${BETA} -eq 1 ]; then
	sysrc plexmediaserver_plexpass_enable="YES"
	sysrc plexmediaserver_plexpass_support_path="/mnt/plex-data"
	service plexmediaserver-plexpass start
else
	sysrc plexmediaserver_enable="YES"
	sysrc plexmediaserver_support_path="/mnt/plex-data"
	service plexmediaserver start
fi	

echo "---------------"
echo "Installation complete."
echo "Plex is running on port 32400."
echo "Go to your /web to start setup."
echo "---------------"
