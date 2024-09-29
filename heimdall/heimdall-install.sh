#!/bin/sh
# Install Heimdall Dashboard

APP_NAME="Heimdall"
APP_VERSION="2.6.1"
PHP_VERSION="83"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y caddy php${PHP_VERSION} php${PHP_VERSION}-mbstring php${PHP_VERSION}-zip php${PHP_VERSION}-tokenizer php${PHP_VERSION}-pdo php${PHP_VERSION}-pdo_sqlite php${PHP_VERSION}-filter php${PHP_VERSION}-xml php${PHP_VERSION}-ctype php${PHP_VERSION}-dom php${PHP_VERSION}-fileinfo sqlite3 php${PHP_VERSION}-session go git

# Create Directories
mkdir -p /usr/local/www

# Heimdall Setup
mkdir -p /usr/local/www/html
fetch -o /tmp https://github.com/linuxserver/Heimdall/archive/v"${APP_VERSION}".tar.gz
tar zxf /tmp/v"${APP_VERSION}".tar.gz --strip 1 -C /usr/local/www/html/
mkdir -p /usr/local/www/html/storage/app/public/icons
sh -c 'find /usr/local/www/ -type d -print0 | xargs -0 chmod 2775'
touch /usr/local/www/html/database/app.sqlite
chmod 664 /usr/local/www/html/database/app.sqlite
cp /usr/local/www/html/.env.example /usr/local/www/html/.env
sh -c 'cd /usr/local/www/html/ && php artisan key:generate'
chown -R www:www /usr/local/www/html/

# Enable and Start Services
fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/heimdall/includes/Caddyfile-nossl
sysrc php_fpm_enable=YES
sysrc caddy_enable=YES
sysrc caddy_config=/usr/local/www/Caddyfile
service php-fpm start
service caddy start

# Done
echo "---------------"
echo "Installation complete!"
echo "${APP_NAME} is running on port 80"
echo "---------------"
