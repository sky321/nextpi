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

# nextcloud aquisition

cat > /etc/crowdsec/acquis.d/nextcloud.yaml << EOF
filenames:
 - $SRCDIR/nextcloud.log
labels:
  type: Nextcloud
EOF

# Dynamic Increase of Blocking Time 

if [[ -f /etc/cowdsec/profiles.yaml ]]; then
      sudo sed -i 's/#duration_expr/duration_expr/' /etc/crowdsec/profiles.yaml
fi

# Allowlist for SURY IPs

#sudo cscli allowlists create my_allowlist --description "central allowlist"
#sudo cscli allowlists add my_allowlist 169.150.247.37 -d "Sury IP"
#sudo cscli allowlists add my_allowlist 169.150.247.38 -d "Sury IP"
#sudo cscli allowlists add my_allowlist 169.150.247.39 -d "Sury IP"

# enable WAL for local sqlite db
grep -q use_wal /etc/crowdsec/config.yaml || sudo sed -i "/db_config:/a\  use_wal: true" /etc/crowdsec/config.yaml

#restart services
systemctl reload crowdsec && systemctl restart crowdsec.service crowdsec-firewall-bouncer.service

# get rid of sury blacklist
for i in 37 38 39; do cscli decisions delete --ip "169.150.247.$i"; done

#cron update job
echo "0 2 * * * /usr/bin/cscli hub update && /usr/bin/cscli hub upgrade > /dev/null 2>&1" >> /var/spool/cron/crontabs/root

}
