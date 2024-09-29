#!/bin/sh
# Install Photoprism

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

APP_NAME="Photoprism"
ADMIN_PASSWORD=$(openssl rand -base64 12)
DB_TYPE="MariaDB"
DB_NAME="photoprism"
DB_USER="photoprism"
DB_ROOT_PASSWORD=$(openssl rand -base64 16)
DB_PASSWORD=$(openssl rand -base64 16)
MARIADB_VERSION="106"
# Libtensorflow Package
# Uncomment for FreeBSD 13
LIBTENSORFLOW_PKG="https://github.com/lapo-luchini/libtensorflow1-freebsd-port/releases/download/v1.15.5_2/libtensorflow1-1.15.5_2.pkg-FreeBSD-13.2-amd64-AVX-SSE42.pkg"
# Uncomment for FreeBSD 14
#LIBTENSORFLOW_PKG="https://github.com/lapo-luchini/libtensorflow1-freebsd-port/releases/download/v1.15.5_2/libtensorflow1-1.15.5_2.pkg-FreeBSD-14.0-amd64-AVX-SSE42.pkg"
# Photoprism Package
# github.com/lapo-luchini
# Uncomment for FreeBSD 13
#PHOTOPRISM_PKG="https://github.com/lapo-luchini/photoprism-freebsd-port/releases/download/2023-11-28/photoprism-g20231128-FreeBSD-13.2-amd64.pkg"
# Uncomment for FreeBSD 14
#PHOTOPRISM_PKG="https://github.com/lapo-luchini/photoprism-freebsd-port/releases/download/2023-11-28/photoprism-g20231128-FreeBSD-14.0-amd64.pkg"
# github.com/Gaojianli
# Uncomment for FreeBSD 13
PHOTOPRISM_PKG="https://github.com/Gaojianli/photoprism-freebsd-port/releases/download/240915-e1280b2fb/photoprism-g20240915-FreeBSD-13.3-RELEASE.pkg"
# Uncomment for FreeBSD 14
#PHOTOPRISM_PKG="https://github.com/Gaojianli/photoprism-freebsd-port/releases/download/240915-e1280b2fb/photoprism-g20240915-FreeBSD-14.1-RELEASE.pkg"

# Check for Reinstall
if [ "$(ls -A /var/db/mysql/"${DB_NAME}" 2>/dev/null)" ]; then
	echo "Existing ${APP_NAME} database detected."
        echo "Starting reinstall..."
	REINSTALL="true"
fi

# Install Packages
pkg install -y vips ffmpeg darktable rawtherapee libheif p5-Image-ExifTool mariadb${MARIADB_VERSION}-server mariadb${MARIADB_VERSION}-client

# Create Directories
mkdir -p /mnt/photos
mkdir -p /var/db/mysql

# Create Database
sysrc mysql_enable="YES"
sysrc mysql_args="--bind-address=127.0.0.1"
service mysql-server start
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall, but database passwords will still be changed."
 	echo "New passwords will still be saved in the root directory."
 	mysql -u root -e "SET PASSWORD FOR '${DB_USER}'@localhost = PASSWORD('${DB_PASSWORD}');"
  	sed -i '' -e "s|.*DatabasePassword:.*|DatabasePassword: ${DB_PASSWORD}|g" /mnt/photos/options.yml
	fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/photoprism/includes/my.cnf
  	sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
else
	if ! mysql -u root -e "CREATE DATABASE ${DB_NAME} CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;"
		then
		echo "Failed to create MariaDB database, aborting"
    		exit 1
	fi
mysql -u root -e "CREATE USER '${DB_USER}'@localhost IDENTIFIED BY '${DB_PASSWORD}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* to '${DB_USER}'@'%';"
mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -u root -e "DROP DATABASE IF EXISTS test;"
mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -u root -e "FLUSH PRIVILEGES;"
mysqladmin --user=root password "${DB_ROOT_PASSWORD}" reload
fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/photoprism/includes/my.cnf
sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
touch /mnt/photos/options.yml
cat >/mnt/photos/options.yml <<EOL
# options.yml
AdminPassword: ${ADMIN_PASSWORD}
AssetsPath: /var/db/photoprism/assets
StoragePath: /mnt/photos
OriginalsPath: /mnt/photos/originals
ImportPath: /mnt/photos/import
DatabaseDriver: mysql
DatabaseName: ${DB_NAME}
DatabaseServer: "127.0.0.1:3306"
DatabaseUser: ${DB_USER}
DatabasePassword: ${DB_PASSWORD}
EOL
fi

# Install Photoprism
pkg add "${LIBTENSORFLOW_PKG}"
pkg add "${PHOTOPRISM_PKG}"

# Enable and Start Services
chown -R photoprism:photoprism /mnt/photos
sysrc photoprism_enable="YES"
sysrc photoprism_assetspath="/var/db/photoprism/assets"
sysrc photoprism_storagepath="/mnt/photos/"
sysrc photoprism_defaultsyaml="/mnt/photos/options.yml"
service photoprism start

# Save Passwords for Later Reference
echo "${DB_TYPE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}-Info.txt
echo "${APP_NAME} database name is ${DB_NAME} and password is ${DB_PASSWORD}" >> /root/${APP_NAME}-Info.txt
echo "${APP_NAME} user is admin password is ${ADMIN_PASSWORD}" >> /root/${APP_NAME}-Info.txt

# Done
echo "---------------"
echo "Installation complete!"
echo "${APP_NAME} is running on port 2342"
echo "---------------"
echo "Database Information"
echo "$DB_TYPE Username: root"
echo "$DB_TYPE Password: $DB_ROOT_PASSWORD"
echo "$APP_NAME DB User: $DB_USER"
echo "$APP_NAME DB Password: $DB_PASSWORD"
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "You did a reinstall"
 	echo "Please use your old credentials to log in."
else
	echo "User Information"
	echo "Default user is admin"
	echo "Devault password is ${ADMIN_PASSWORD}"
 	echo "---------------"
fi
echo "All passwords are saved in /root/${APP_NAME}-Info.txt"
echo "---------------"
