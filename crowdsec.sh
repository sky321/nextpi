#!/bin/bash
##########################################################################################
# CROWDSEC INSTALLATION
##########################################################################################
# Debian 12 / Ubuntu 22.04+ LTS x86_64
# Carsten Rieger IT-Services (https://www.c-rieger.de)
##########################################################################################

install()
{
echo ""
echo " » fail2ban wird entfernt  // remove fail2ban"
echo ""

systemctl stop fail2ban.service
systemctl disable fail2ban.service
systemctl mask fail2ban.service
apt-get remove fail2ban --purge -y

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

systemctl enable --now crowdsec.service

cscli collections install crowdsecurity/nextcloud
cscli collections install crowdsecurity/apache2
cscli collections install crowdsecurity/sshd
systemctl reload crowdsec && systemctl restart crowdsec

cp /etc/crowdsec/acquis.yaml /etc/crowdsec/acquis.yaml.bak
cat <<EOF >>/etc/crowdsec/acquis.yaml
#Nextcloud by c-rieger.de
filenames:
 - /var/log/nextcloud/nextcloud.log
labels:
  type: Nextcloud
---
EOF

systemctl reload crowdsec && systemctl restart crowdsec.service crowdsec-firewall-bouncer.service

}