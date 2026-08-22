#!/bin/sh
# Install Crafty Controller

APP_NAME="Crafty"
OPENJDK_VERSION="25"
PYTHON_VERSION="312"
TIME_ZONE="America/Edmonton"

# Check for Root Privileges
if ! [ "$(id -u)" = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

update_app() {
    su - crafty -c '. .venv/bin/activate
                    cd crafty
                    git reset --hard origin/master
                    git fetch && git pull
                    pip3 install --no-cache-dir -r requirements.txt'
	supervisorctl restart crafty
}

case "${1}" in
    -u|--update)
        update_app
		exit 0
        ;;
esac

# Packages
pkg install -y \
bash \
git-tiny \
openjdk${OPENJDK_VERSION} \
python3 \
python${PYTHON_VERSION} \
py${PYTHON_VERSION}-pip \
py${PYTHON_VERSION}-sqlite3 \
py${PYTHON_VERSION}-supervisor \
rust

# User and Directories
id -u crafty 2>&1 || pw useradd -n crafty -d /var/games/minecraft -s /usr/local/bin/bash -m

# Install
su - crafty -c 'python3 -m venv .venv
                . .venv/bin/activate
				git clone https://gitlab.com/crafty-controller/crafty-4.git crafty
				cd crafty
				pip3 install --no-cache-dir -r requirements.txt
				pip install --upgrade pip
				mkdir /var/games/minecraft/servers'
cat <<EOF >>/usr/local/etc/supervisord.conf
[program:crafty]
command=/var/games/minecraft/.venv/bin/python3 main.py -d
directory=/var/games/minecraft/crafty
user=crafty
environment=TZ="${TIME_ZONE}",PATH="/usr/local/bin:/usr/bin:/bin"
EOF

# Services
sysrc supervisord_enable=YES
service supervisord start
sleep 10

# Passwords
ADMIN_USER="$(cat /var/games/minecraft/crafty/app/config/default-creds.txt | grep '"username"' | awk -F": " '{print $2}' | sed 's/[",]//g')"
ADMIN_PASSWORD="$(cat /var/games/minecraft/crafty/app/config/default-creds.txt | grep '"password"' | awk -F": " '{print $2}' | sed 's/[",]//g')"
echo "${APP_NAME} user is ${ADMIN_USER} and password is ${ADMIN_PASSWORD}" > /root/${APP_NAME}-Info.txt

# Done
echo "---------------"
echo "Installation Complete."
echo "${APP_NAME} is running on port 8443."
echo "---------------"
echo "User Information"
echo "Default ${APP_NAME} user is ${ADMIN_USER}"
echo "Default ${APP_NAME} password is ${ADMIN_PASSWORD}"
echo "--------------------"
echo "All passwords are saved in /root/${APP_NAME}-Info.txt"
echo "---------------"
