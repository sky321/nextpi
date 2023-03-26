#!/bin/bash

# Nextcloud LAMP base installation on Raspbian 
#
# Copyleft 2017 by Ignacio Nunez Hernanz <nacho _a_t_ ownyourbits _d_o_t_ com>
# GPL licensed (see end of file) * Use at your own risk!
#
# Usage: Before you start check and refine what is to be installed
# 
#   dpkg -l | grep php | tee php.txt
#   php -v
#
# Nachher evtl. apt-get remove --purge ${PHPALT}*
#
# 

PHPALT=$( grep PHPVER /root/.nextpi.cnf | sed 's|PHPVER=||' )
PHPVER=8.1
DATADIR=$( grep CHGDATADIR /root/.nextpi.cnf | sed 's|CHGDATADIR=||' )
RELEASE=$( grep RELEASE /root/.nextpi.cnf | sed 's|RELEASE=||' )

APTINSTALL="apt-get install -y --no-install-recommends"
export DEBIAN_FRONTEND=noninteractive

MAXFILESIZE=2G
MEMORYLIMIT=768M
MAXTRANSFERTIME=3600

apt-get update && sudo apt-get dist-upgrade
[ -f /var/run/reboot-required ] && { echo "Reboot required"; read -p "Press ENTER to reboot or ^C to cancel" dummy; sudo systemctl reboot; exit; } || echo "No reboot required"

#service apache2 stop
#service mysql stop
#service php${PHPALT}-fpm stop

    # INSTALL 
    ##########################################

packages="$(echo $(dpkg -l | awk '/^ii/ {print $2}' | grep -i $PHPALT | sed 's/$PHPALT/$PHPVER/g'))"
apt-get install $packages

#    $APTINSTALL -t $RELEASE php${PHPVER} libapache2-mod-php${PHPVER} php${PHPVER}-curl php${PHPVER}-gd php${PHPVER}-fpm libapache2-mod-fcgid php${PHPVER}-cli php${PHPVER}-opcache php${PHPVER}-mbstring php${PHPVER}-xml php${PHPVER}-zip php${PHPVER}-common php${PHPVER}-ldap php${PHPVER}-intl php${PHPVER}-bz2 php${PHPVER}-gmp php${PHPVER}-bcmath php${PHPVER}-mysql php${PHPVER}-smbclient php${PHPVER}-imagick php${PHPVER}-exif php${PHPVER}-redis php${PHPVER}-igbinary php${PHPVER}-readline

    # CONFIGURE PHP
    ##########################################

    cat > /etc/php/${PHPVER}/mods-available/opcache.ini <<EOF
zend_extension=opcache.so
opcache.enable=1
opcache.enable_cli=1
opcache.fast_shutdown=1
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.memory_consumption=128
opcache.save_comments=1
opcache.revalidate_freq=1
opcache.file_cache=/tmp;
EOF

  # opcache dir
  sed -i "s|^opcache.file_cache=.*|opcache.file_cache=$DATADIR/.opcache|" /etc/php/${PHPVER}/mods-available/opcache.ini

# tmp upload dir
  mkdir -p "$DATADIR/tmp" 
  chown www-data:www-data "$DATADIR/tmp"
  sudo -u www-data php occ config:system:set tempdirectory --value "$DATADIR/tmp"
  sed -i "s|^;\?upload_tmp_dir =.*$|uploadtmp_dir = $DATADIR/tmp|" /etc/php/${PHPVER}/cli/php.ini
  sed -i "s|^;\?upload_tmp_dir =.*$|upload_tmp_dir = $DATADIR/tmp|" /etc/php/${PHPVER}/fpm/php.ini
  sed -i "s|^;\?sys_temp_dir =.*$|sys_temp_dir = $DATADIR/tmp|"     /etc/php/${PHPVER}/fpm/php.ini

  # memory limit php
  sed -i "s|^;\?memory_limit =.*$|memory_limit = $MEMORYLIMIT|"     /etc/php/${PHPVER}/cli/php.ini
  sed -i "s|^;\?memory_limit =.*$|memory_limit = $MEMORYLIMIT|"     /etc/php/${PHPVER}/fpm/php.ini
  
  # upload limit php
  sed -i "s|^;\?upload_max_filesize =.*$|upload_max_filesize = $MAXFILESIZE|"     /etc/php/${PHPVER}/cli/php.ini
  sed -i "s|^;\?upload_max_filesize =.*$|upload_max_filesize = $MAXFILESIZE|"     /etc/php/${PHPVER}/fpm/php.ini
  sed -i "s|^;\?post_max_size =.*$|post_max_size = $MAXFILESIZE|"     /etc/php/${PHPVER}/cli/php.ini
  sed -i "s|^;\?post_max_size =.*$|post_max_size = $MAXFILESIZE|"     /etc/php/${PHPVER}/fpm/php.ini
  
  # session cockie secure PHP
  sed -i "s/;session.cookie_secure.*/session.cookie_secure = True/" /etc/php/${PHPVER}/cli/php.ini
  sed -i "s/;session.cookie_secure.*/session.cookie_secure = True/" /etc/php/${PHPVER}/fpm/php.ini

a2disconf php${PHPALT}-fpm
a2enconf php${PHPVER}-fpm
systemctl reload apache2

#service mysql start
#service php${PHPVER}-fpm start
#service apache2 start

#update-alternatives --config  php

  # Nextcloud Server update:

#sudo -u www-data php -f /var/www/nextcloud/occ app:update --all
#sudo -u www-data php -f /var/www/nextcloud/updater/updater.phar



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

