#!/bin/sh
# Install Audiobookshelf

APP_NAME="Audiobookshelf"
APP_VERSION="2.36.0"
DATA_PATH="/mnt/data"
NODE_VERSION="20"

# Check for Root Privileges
if ! [ "$(id -u)" = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Packages
pkg install -y \
cmake \
ffmpeg \
git-lite \
gmake \
jq \
node"${NODE_VERSION}" \
npm-node"${NODE_VERSION}" \
python3 \
sqlite3

# Directories/Files
mkdir -p "${DATA_PATH}"/audiobookshelf/metadata
mkdir -p "${DATA_PATH}"/audiobookshelf/backups
mkdir -p /usr/local/etc/audiobookshelf/config
mkdir -p /usr/local/www/audiobookshelf
mkdir -p /usr/local/etc/rc.d
mkdir -p /usr/local/lib/nusqlite3
touch /usr/local/etc/audiobookshelf/.env

# SQlite3
NUSQLITE3="$(fetch -qo - "https://api.github.com/repos/mikiher/nunicode-sqlite/releases/latest" | jq -r '.tag_name')"
git clone --depth=1 --branch=1.11 https://bitbucket.org/alekseyt/nunicode.git /tmp/nunicode
git clone --depth=1 --branch="${NUSQLITE3}" https://github.com/mikiher/nunicode-sqlite.git /tmp/nunicode-sqlite
cp /tmp/nunicode-sqlite/cmake/* /tmp/nunicode/cmake/
cp /tmp/nunicode-sqlite/CMakeLists.txt /tmp/nunicode/
mkdir -p /tmp/nunicode/include
cp /usr/local/include/sqlite3*.h /tmp/nunicode/include/
mkdir -p /tmp/nunicode/staging
cd /tmp/nunicode/staging && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_MAKE_PROGRAM=/usr/local/bin/gmake -G "Unix Makefiles"
cd /tmp/nunicode/staging && gmake nusqlite3
cp /tmp/nunicode/staging/sqlite3/libnusqlite3.so /usr/local/lib/nusqlite3/
rm -r /tmp/nunicode*

# Audiobookshelf
id -u audiobookshelf >/dev/null 2>&1 || pw user add audiobookshelf -c audiobookshelf -u 3333 -d /nonexistent -s /usr/bin/nologin
npm install npm -g
fetch -qo /tmp/"${APP_NAME}".tar.gz "https://github.com/advplyr/audiobookshelf/archive/refs/tags/v${APP_VERSION}.tar.gz"
mkdir /tmp/"${APP_NAME}"
tar -xz -f /tmp/"${APP_NAME}".tar.gz --strip-components=1 -C /usr/local/www/audiobookshelf
rm -r /tmp/"${APP_NAME}".tar.gz
cd /usr/local/www/audiobookshelf/client && npm ci
cd /usr/local/www/audiobookshelf/client && npm run generate
cd /usr/local/www/audiobookshelf/server && npm install --omit=dev --omit=optional --ignore-scripts
cd /usr/local/www/audiobookshelf/server && npm rebuild sqlite3
chown -R audiobookshelf:audiobookshelf /usr/local/www/audiobookshelf
chown -R audiobookshelf:audiobookshelf /usr/local/etc/audiobookshelf
chown -R audiobookshelf:audiobookshelf "${DATA_PATH}"

# Services
fetch -o /usr/local/etc/rc.d https://raw.githubusercontent.com/tschettervictor/bsd-apps/master/audiobookshelf/includes/audiobookshelf
chmod +x /usr/local/etc/rc.d/audiobookshelf
sysrc audiobookshelf_enable="YES"
sysrc audiobookshelf_datadir="${DATA_PATH}/audiobookshelf"
sysrc audiobookshelf_configdir="/usr/local/etc/audiobookshelf"
service audiobookshelf start

# Done
echo "---------------"
echo "Installation Complete!"
echo "${APP_NAME} is running on port 3333"
echo "---------------"
