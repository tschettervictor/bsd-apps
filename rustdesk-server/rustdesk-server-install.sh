pkg install -y rustdesk-server
sysrc rustdesk_hbbr_enable=YES
sysrc rustdesk_hbbs_enable=YES
service rustdesk-hbbr start
service ristdesk-hbbs start
