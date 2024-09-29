#!/bin/sh
# Install Photoprism

APP_NAME="photoprism"
DATABASE_TYPE="MariaDB"
MARIADB_VERSION="106"
DB_USER="photoprism"
DB_NAME="photoprism"
ADMIN_PASSWORD=$(openssl rand -base64 12)
DB_PASSWORD=$(openssl rand -base64 16)
DB_ROOT_PASSWORD=$(openssl rand -base64 16)

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

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Check for Reinstall
if [ "$(ls -A /var/db/mysql/"${DB_NAME}" 2>/dev/null)" ]; then
	echo "Existing Photoprism database detected."
	REINSTALL="true"
 	else echo "No existing database detected. Starting full install."
fi

# Install Packages
pkg install -y ffmpeg darktable rawtherapee libheif p5-Image-ExifTool mariadb${MARIADB_VERSION}-server mariadb${MARIADB_VERSION}-client

# Create Directories
mkdir -p /mnt/photos
mkdir -p /var/db/mysql

# Create Database
sysrc mysql_enable="YES"
sysrc mysql_args="--bind-address=127.0.0.1"
service mysql-server start
if [ "${REINSTALL}" == "true" ]; then
	echo "Reinstall detected, skipping generation of new database and credentials."
  fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/photoprism/includes/my.cnf
  sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf
else
	if ! mysql -u root -e "CREATE DATABASE ${DB_NAME} CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;"
		then
		echo "Failed to create MariaDB database, aborting"
    		exit 1
	fi
mysql -u root -e "CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* to '${DB_USER}'@'%';"
mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -u root -e "DROP DATABASE IF EXISTS test;"
mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -u root -e "FLUSH PRIVILEGES;"
mysqladmin --user=root password "${DB_ROOT_PASSWORD}" reload
fetch -o /root/.my.cnf https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/photoprism/includes/my.cnf
sed -i '' "s|mypassword|${DB_ROOT_PASSWORD}|" /root/.my.cnf

# Save Passwords for Later Reference
echo "${DATABASE_TYPE} root user is root and password is ${DB_ROOT_PASSWORD}" > /root/${APP_NAME}_passwords.txt
echo "Photoprism database name is ${DB_NAME} and password is ${DB_PASSWORD}" >> /root/${APP_NAME}_passwords.txt
echo "Photoprism user is admin password is ${ADMIN_PASSWORD}" >> /root/${APP_NAME}_passwords.txt
echo "Passwords for Database and admin user have been saved in root directory."
fi

# Install Photoprism
pkg add "${LIBTENSORFLOW_PKG}"
pkg add "${PHOTOPRISM_PKG}"

# Enable and Start Services
sysrc photoprism_enable="YES"
sysrc photoprism_assetspath="/var/db/photoprism/assets"
sysrc photoprism_storagepath="/mnt/photos/"
sysrc photoprism_defaultsyaml="/mnt/photos/options.yml"
touch /mnt/photos/options.yml
if [ "${REINSTALL}" == "true" ]; then
	echo "No need to copy options.yml file on a reinstall."
else
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
chown -R photoprism:photoprism /mnt/photos
service photoprism start

echo "---------------"
echo "Installation complete!"
echo "Photoprism is runnin on port 2342"
echo "---------------"
if [ "${REINSTALL}" == "true" ]; then
	echo "---------------"
	echo "You did a reinstall, please use your old database and account credentials."
else
	echo "---------------"
	echo "Database Information"
	echo "Database user = ${DB_USER}"
	echo "Database password = ${DB_PASSWORD}"
	echo "---------------"
 	echo "User Information"
	echo "Default user = admin"
 	echo "Devault password is ${ADMIN_PASSWORD}"
  	echo "---------------"
	echo "All passwords are saved in /root/${APP_NAME}_passwords.txt"
fi
