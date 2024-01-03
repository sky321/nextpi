#!/bin/bash
##########################################################################################
# CROWDSEC INSTALLATION
##########################################################################################
# Debian 12 / Ubuntu 22.04+ LTS x86_64
# Carsten Rieger IT-Services (https://www.c-rieger.de)
##########################################################################################

install()
{
#echo ""
#echo " » fail2ban wird entfernt  // remove fail2ban"
#echo ""

#systemctl stop fail2ban.service
#systemctl disable fail2ban.service
#systemctl mask fail2ban.service
#apt-get remove fail2ban --purge -y

echo ""
echo " » Crowdsec wird heruntergeladen+installiert // crowdsec will be downloaded+installed"
echo ""

curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
apt-get install crowdsec -y
apt-get install crowdsec-firewall-bouncer-nftables -y

}

configure()
{
echo ""
echo " » Crowdsec wird konfiguriert // crowdsec will be configured"
echo ""

SRCDIR=$( cd /var/www/nextcloud; sudo -u www-data php occ config:system:get datadirectory ) || {
    echo -e "Error reading data directory. Is NextCloud running and configured?"; 
    exit 1;
  }

systemctl enable --now crowdsec.service

cscli collections install crowdsecurity/nextcloud
cscli collections install crowdsecurity/apache2
cscli collections install crowdsecurity/sshd
systemctl reload crowdsec && systemctl restart crowdsec

cp /etc/crowdsec/acquis.yaml /etc/crowdsec/acquis.yaml.bak
cat <<EOF >>/etc/crowdsec/acquis.yaml
#Nextcloud by c-rieger.de
filenames:
 - $SRCDIR/nextcloud.log
labels:
  type: Nextcloud
---
EOF

# get IP
IFACE="$( ip r | grep "default via" | awk '{ print $5 }' | head -1 )"
IP="$( ip a show dev "$IFACE" | grep global | grep -oP '\d{1,3}(.\d{1,3}){3}' | head -1 )"

cat > /etc/crowdsec/parsers/s02-enrich/personal-whitelist.yaml << EOF
name: crowdsecurity/whitelists
description: "Whitelist events from my personal ips"
whitelist:
  reason: "internal traffic from my personal ips"
  ip:
    - "$IP"
    - "127.0.0.1/8"
EOF

#cron update job
echo "0 2 * * * /usr/bin/cscli hub update && /usr/bin/cscli hub upgrade > /dev/null 2>&1" >> /var/spool/cron/crontabs/root

#restart services
systemctl reload crowdsec && systemctl restart crowdsec.service crowdsec-firewall-bouncer.service

}