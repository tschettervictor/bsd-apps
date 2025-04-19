#!/bin/sh
# Install SLSKD
set -eu

APP_NAME="SLSKD"
FREEBSD_VERSION="13"
NODE_VERSION="20"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Package Installation
pkg install -y \
dotnet \
git-lite \
npm-node${NODE_VERSION} \
sqlite3

# Create Directories
mkdir -p /usr/local/www
mkdir -p /usr/local/etc/rc.d

# SLSKD Setup
id -u soulseek 2>&1 || pw user add soulseek -c soulseek -u 5030 -d /nonexistent -s /usr/bin/nologin
if [ -d "/slskd" ]; then
    cd /slskd && git reset --hard HEAD
    cd /slskd && git pull
else
    git clone https://github.com/slskd/slskd /slskd
fi
cd /slskd/src/web && npm install
cd /slskd/src/web && npm run build
rm -rf /slskd/src/slskd/wwwroot
cp -a /slskd/src/web/build /slskd/src/slskd/wwwroot
sed -i '' 's/net8.0/net9.0/g' /slskd/src/slskd/slskd.csproj
cd /slskd/src/slskd && dotnet build \
    --no-incremental \
    --nologo \
    --configuration Release
cd /slskd/src/slskd && dotnet publish \
    -c Release \
    --runtime freebsd."${FREEBSD_VERSION}"-x64 \
    --framework net9.0 \
    -p:ReadyToRun=true \
    -p:PublishSingleFile=true \
    -p:IncludeNativeLibrariesForSelfExtract=true \
    -p:Version=$(git describe --tags --abbrev=0)+$(git rev-parse --short HEAD) \
    --output ../../../usr/local/www/slskd \
    --self-contained &&
cd /usr/local/www/slskd && ln -s /usr/local/lib/libsqlite3.so libe_sqlite3.so
if ! [ -f "/usr/local/www/slskd/slskd.yml" ]; then
   cp /usr/local/www/slskd/config/slskd.example.yml /usr/local/www/slskd/slskd.yml
fi
chown -R soulseek:soulseek /usr/local/www/slskd

# Enable and Start Services
fetch -o /usr/local/etc/rc.d/slskd https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/slskd/includes/slskd
chmod +x /usr/local/etc/rc.d/slskd
sysrc slskd_enable=YES
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
