#!/bin/sh
# Install SLSKD

APP_NAME="SLSKD"
NODE_VERSION="20"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Package Installation
pkg install -y git-lite dotnet sqlite3 npm-node${NODE_VERSION}

# Create Directories
mkdir -p /usr/local/www
mkdir -p /usr/local/etc/rc.d

# SLSKD Setup
pw user add soulseek -c soulseek -u 5030 -d /nonexistent -s /usr/bin/nologin
git clone https://github.com/slskd/slskd /slskd
cd /slskd/src/web && npm install
cd /slskd/src/web && npm run build
rm -rf /slskd/src/slskd/wwwroot
cp -av /slskd/src/web/build /slskd/src/slskd/wwwroot
cd /slskd/src/slskd && dotnet build --no-incremental --nologo --configuration Release
cd /slskd/src/slskd && dotnet publish --configuration Release -p:PublishSingleFile=true -p:ReadyToRun=true -p:IncludeNativeLibrariesForSelfExtract=true -p:CopyOutputSymbolsToPublishDirectory=false --self-contained --output ../../../usr/local/www/slskd
cd /usr/local/www/slskd && ln -s /usr/local/lib/libsqlite3.so libe_sqlite3.so
if ! [ -f "/usr/local/www/slskd/slskd.yml" ]; then
   cp /usr/local/www/slskd/config/slskd.example.yml /usr/local/www/slskd/slskd.yml
fi
chown -R soulseek:soulseek /usr/local/www/slskd

# Enable and Start Services
fetch -o /usr/local/etc/rc.d/slskd https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/slskd/includes/slskd
chmod +x /usr/local/etc/rc.d/slskd
sysrc slsdk_enable=YES
service slskd start

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 5030."
echo "---------------"
echo "User Information"
echo "Default ${APP_NAME} user is slskd"
echo "Default ${APP_NAME} password is slskd"
echo "---------------"
