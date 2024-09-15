#!/bin/sh
# Install Tautulli

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y bash python py${PYTHON_VERSION}-setuptools py${PYTHON_VERSION}-sqlite3 py${PYTHON_VERSION}-openssl py${PYTHON_VERSION}pycryptodomex ca_root_nss git-lite

# Create Directories
mkdir -p /data

# Install Tautulli
if ! git clone https://github.com/Tautulli/Tautulli.git /usr/local/share/Tautulli
then
	echo "Failed to clone Tautulli"
	exit 1
fi
pw user add tautulli -c tautulli -u 109 -d /nonexistent -s /usr/bin/nologin
chown -R tautulli:tautulli /usr/local/share/Tautulli /data
cp /usr/local/share/Tautulli/init-scripts/init.freebsd /usr/local/etc/rc.d/tautulli
chmod u+x /usr/local/etc/rc.d/tautulli

# Enable and Start Services
sysrc tautulli_enable="YES"
sysrc tautulli_user=tautulli
sysrc "tautulli_flags=--datadir /data"

echo "---------------"
echo "Installation complete."
echo "Tautulli is running on port 8181"
echo "---------------"
