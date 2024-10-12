#!/bin/sh
# Install MediaMTX

GO_VERSION="122"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y git-lite go${GO_VERSION}

# Create Directories
mkdir -p /usr/local/www/mediamtx
mkdir -p /usr/local/etc/rc.d

# MediaMTX Setup
git clone https://github.com/bluenviron/mediamtx /mediamtx
cd /mediamtx && go122 generate ./...
cd /mediamtx && go122 build .
cp /mediamtx/mediamtx /usr/local/bin/mediamtx
chmod +x /usr/local/bin/mediamtx
if ! [ -f "/usr/local/www/mediamtx/mediamtx.yml" ]; then
    cp /mediamtx/mediamtx.yml /usr/local/www/mediamtx/
fi
rm -R /mediamtx
fetch -o /usr/local/etc/rc.d/mediamtx https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/mediamtx/includes/mediamtx
chmod +x /usr/local/etc/rc.d/mediamtx
pw user add mediamtx -c mediamtx -u 1935 -d /nonexistent -s /usr/bin/nologin
chown -R mediamtx:mediamtx /usr/local/www/mediamtx

# Enable and Start Services
sysrc mediamtx_config="/usr/local/www/mediamtx/mediamtx.yml"
sysrc mediamtx_enable="YES"
service mediamtx start

# Done
echo "---------------"
echo "Installation Complete!"
echo "MediaMTX is now installed and running. See the config file to configure preferred streaming protocols."
echo "---------------"
