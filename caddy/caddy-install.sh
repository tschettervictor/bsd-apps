#!/bin/sh
# Install Caddy

HOST_NAME=""
SELFSIGNED_CERT=0
STANDALONE_CERT=0
DNS_CERT=0
NO_CERT=0
DNS_PLUGIN=""
DNS_TOKEN=""
CERT_EMAIL=""

# Check for Root Privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Variable Checks
if [ -z "${HOST_NAME}" ]; then
  echo 'Configuration error: HOST_NAME must be set'
  exit 1
fi
if [ $STANDALONE_CERT -eq 0 ] && [ $DNS_CERT -eq 0 ] && [ $NO_CERT -eq 0 ] && [ $SELFSIGNED_CERT -eq 0 ]; then
  echo 'Configuration error: Either STANDALONE_CERT, DNS_CERT, NO_CERT,'
  echo 'or SELFSIGNED_CERT must be set to 1.'
  exit 1
fi
if [ $STANDALONE_CERT -eq 1 ] && [ $DNS_CERT -eq 1 ] ; then
  echo 'Configuration error: Only one of STANDALONE_CERT and DNS_CERT'
  echo 'may be set to 1.'
  exit 1
fi
if [ $DNS_CERT -eq 1 ] && [ -z "${DNS_PLUGIN}" ] ; then
  echo "DNS_PLUGIN must be set to a supported DNS provider."
  echo "See https://caddyserver.com/download for available plugins."
  echo "Use only the last part of the name.  E.g., for"
  echo "\"github.com/caddy-dns/cloudflare\", enter \"coudflare\"."
  exit 1
fi
if [ $DNS_CERT -eq 1 ] && [ "${CERT_EMAIL}" = "" ] ; then
  echo "CERT_EMAIL must be set when using Let's Encrypt certs."
  exit 1
fi
if [ $STANDALONE_CERT -eq 1 ] && [ "${CERT_EMAIL}" = "" ] ; then
  echo "CERT_EMAIL must be set when using Let's Encrypt certs."
  exit 1
fi

# Install Packages
pkg install -y go git-lite openssl

# Create Directories
mkdir -p /usr/local/etc/rc.d
mkdir -p /usr/local/www

# Build xcaddy, use it to build Caddy
if ! go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
then
  echo "Failed to get xcaddy, terminating."
  exit 1
fi
if ! cp /root/go/bin/xcaddy /usr/local/bin/xcaddy
then
  echo "Failed to move xcaddy to path, terminating."
  exit 1
fi
if [ ${DNS_CERT} -eq 1 ]; then
  if ! xcaddy build --output /usr/local/bin/caddy --with github.com/caddy-dns/"${DNS_PLUGIN}"
  then
    echo "Failed to build Caddy with ${DNS_PLUGIN} plugin, terminating."
    exit 1
  fi  
else
  if ! xcaddy build --output /usr/local/bin/caddy
  then
    echo "Failed to build Caddy without plugin, terminating."
    exit 1
  fi  
fi
# Generate and insall self-signed cert, if necessary
if [ $SELFSIGNED_CERT -eq 1 ]; then
	mkdir -p /usr/local/etc/pki/tls/private
	mkdir -p /usr/local/etc/pki/tls/certs
	openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=${HOST_NAME}" -keyout /tmp/privkey.pem -out /tmp/fullchain.pem
	cp /tmp/privkey.pem /usr/local/etc/pki/tls/private/privkey.pem
	cp /tmp/fullchain.pem /usr/local/etc/pki/tls/certs/fullchain.pem
fi
if [ $STANDALONE_CERT -eq 1 ] || [ $DNS_CERT -eq 1 ]; then
  fetch -o /root/remove-staging.sh https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/caddy/includes/remove-staging.sh
  chmod +x remove-staging.sh
fi
if [ $NO_CERT -eq 1 ]; then
	echo "Fetching Caddyfile for no SSL"
 	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/caddy/includes/Caddyfile-nossl
elif [ $SELFSIGNED_CERT -eq 1 ]; then
	echo "Fetching Caddyfile for self-signed cert"
	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/caddy/includes/Caddyfile-selfsigned
elif [ $DNS_CERT -eq 1 ]; then
	echo "Fetching Caddyfile for Lets's Encrypt DNS cert"
	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/caddy/includes/Caddyfile-dns
else
	echo "Fetching Caddyfile for Let's Encrypt cert"
	fetch -o /usr/local/www/Caddyfile https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/caddy/includes/Caddyfile-standalone	
fi
fetch -o /usr/local/etc/rc.d/caddy https://raw.githubusercontent.com/tschettervictor/bsd-apps/main/caddy/includes/caddy
chmod +x /usr/local/etc/rc.d/caddy
sed -i '' "s/yourhostnamehere/${HOST_NAME}/" /usr/local/www/Caddyfile
sed -i '' "s/dns_plugin/${DNS_PLUGIN}/" /usr/local/www/Caddyfile
sed -i '' "s/api_token/${DNS_TOKEN}/" /usr/local/www/Caddyfile
sed -i '' "s/youremailhere/${CERT_EMAIL}/" /usr/local/www/Caddyfile

# Enable and Start Services
sysrc caddy_config="/usr/local/www/Caddyfile"
sysrc caddy_enable="YES"
service caddy start

echo "---------------"
echo "Installation complete."
echo "---------------"
if [ $STANDALONE_CERT -eq 1 ] || [ $DNS_CERT -eq 1 ]; then
  echo "You have obtained your Let's Encrypt certificate using the staging server."
  echo "This certificate will not be trusted by your browser and will cause SSL errors"
  echo "when you connect.  Once you've verified that everything else is working"
  echo "correctly, you should issue a trusted certificate.  To do this, run:"
  echo "/root/remove-staging.sh"
  echo ""
elif [ $SELFSIGNED_CERT -eq 1 ]; then
  echo "You have chosen to create a self-signed TLS certificate for your installation."
  echo "installation.  This certificate will not be trusted by your browser and"
  echo "will cause SSL errors when you connect.  If you wish to replace this certificate"
  echo "with one obtained elsewhere, the private key is located at:"
  echo "/usr/local/etc/pki/tls/private/privkey.pem"
  echo "The full chain (server + intermediate certificates together) is at:"
  echo "/usr/local/etc/pki/tls/certs/fullchain.pem"
  echo ""
fi
echo "---------------"
if [ $NO_CERT -eq 1 ]; then
  echo "Using your web browser, go to http://${HOST_NAME} to access your installation."
else
  echo "Using your web browser, go to https://${HOST_NAME} to access your installation."
fi
