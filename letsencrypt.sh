#!/bin/bash

# Let's encrypt certbot installation on Raspbian 
#
# Copyleft 2017 by Ignacio Nunez Hernanz <nacho _a_t_ ownyourbits _d_o_t_ com>
# GPL licensed (see end of file) * Use at your own risk!
#
# More at https://ownyourbits.com/2017/03/17/lets-encrypt-installer-for-apache/
#
# https://certbot.eff.org/docs/using.html
#
# tested with certbot 0.28.0
#

DOMAIN_=mycloud.ownyourbits.com  # replace with your own domain
EMAIL_=mycloud@ownyourbits.com   # replace with your own email
#NOTIFYUSER_=ncp                  # replace with your own nextcloud user

#NCDIR=/var/www/nextcloud
#OCC="$NCDIR/occ"
VHOSTCFG=/etc/apache2/sites-available/nextcloud.conf
DESCRIPTION="Automatic signed SSL certificates"

INFOTITLE="Warning"
INFO="Internet access is required for this configuration to complete
Both ports 80 and 443 need to be accessible from the internet
 
Your certificate will be automatically renewed every month"


  cd /etc || exit 1
  apt-get update
#  apt-get install --no-install-recommends -y certbot
  apt-get install --no-install-recommends -y certbot python3-certbot-apache
#  mkdir -p /etc/letsencrypt/live

  DOMAIN_LOWERCASE="${DOMAIN_,,}"
  
  # Configure Apache
  grep -q ServerName $VHOSTCFG && \
    sed -i "s|ServerName .*|ServerName $DOMAIN_|" $VHOSTCFG || \
    sed -i "/DocumentRoot/aServerName $DOMAIN_" $VHOSTCFG 

  # Do it
  #
#  certbot certonly -n --webroot -w $NCDIR --hsts --agree-tos -m $EMAIL_ -d $DOMAIN_ && {
  certbot certonly -n --apache --hsts --agree-tos --rsa-key-size 4096 -m $EMAIL_ -d $DOMAIN_ && {

    # Configure Apache
    sed -i "s|SSLCertificateFile.*|SSLCertificateFile /etc/letsencrypt/live/$DOMAIN_LOWERCASE/fullchain.pem|" $VHOSTCFG
    sed -i "s|SSLCertificateKeyFile.*|SSLCertificateKeyFile /etc/letsencrypt/live/$DOMAIN_LOWERCASE/privkey.pem|" $VHOSTCFG

    # Configure Nextcloud
    sudo -u www-data php $OCC config:system:set trusted_domains 0 --value=$DOMAIN_
    sudo -u www-data php $OCC config:system:set overwrite.cli.url --value=https://"$DOMAIN_"/

    # delayed in bg so it does not kill the connection, and we get AJAX response
    bash -c "sleep 2 && service apache2 reload" &>/dev/null &
#    rm -rf $NCDIR/.well-known

#    
# pre and post hooks see https://github.com/certbot/certbot/issues/1706
	echo "pre-hook = /bin/run-parts /etc/letsencrypt/renewal-hooks/pre/" >> /etc/letsencrypt/cli.ini
	echo "post-hook = /bin/run-parts /etc/letsencrypt/renewal-hooks/post/" >> /etc/letsencrypt/cli.ini
	cp pre-hook.sh /etc/letsencrypt/renewal-hooks/pre
	cp post-hook.sh /etc/letsencrypt/renewal-hooks/post
	
    echo "Letsencrypt is finished successful
	run sudo certbot renew --dry-run 
	to see if it's OK"
    exit 0
  }
#  rm -rf $NCDIR/.well-known
  echo "something went wrong with the cert"
  exit 1

# License
#
# This script is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this script; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA  02111-1307  USA

