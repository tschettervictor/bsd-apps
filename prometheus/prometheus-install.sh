#!/bin/sh
# Install Prometheus

APP_NAME="Prometheus"

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Install Packages
pkg install -y \
prometheus

# Create Directories
mkdir -p /usr/local/etc/prometheus
mkdir -p /var/db/prometheus

# Enable, Configure and Start Services
sysrc prometheus_enable=YES
sysrc prometheus_config="/usr/local/etc/prometheus/prometheus.yml"
service prometheus start

# Done
echo "---------------"
echo "Installation complete."
echo "${APP_NAME} is running on port 9090."
echo "---------------"
