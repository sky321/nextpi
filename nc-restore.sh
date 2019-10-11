#!/bin/bash

# Nextcloud restore backup
#
# Copyleft 2017 by Ignacio Nunez Hernanz <nacho _a_t_ ownyourbits _d_o_t_ com>
# GPL licensed (see end of file) * Use at your own risk!
#
# More at https://ownyourbits.com/2017/02/13/nextcloud-ready-raspberry-pi-image/
#

DESCRIPTION="Restore a previously backuped NC instance"

INFOTITLE="Restore NextCloud backup"
INFO="This new installation will cleanup current
NextCloud instance, including files and database."

NCDIR=/var/www/nextcloud
BACKUPDIR=$( grep RESTOREDIR /root/.nextpi.cnf | sed 's|RESTOREDIR=||' )
DBNAME=nextcloud
DBADMIN=$( grep DBADMIN /root/.nextpi.cnf | sed 's|DBADMIN=||' )
DBPASSWD="$( grep password /root/.my.cnf | sed 's|password=||' )"
PHPVER=$( grep PHPVER /root/.nextpi.cnf | sed 's|PHPVER=||' )

cd "$NCDIR"
sudo -u www-data php occ maintenance:mode --on

## BACKUP OLD FILES and DB FILES
echo "backup active files and db..."
sudo rsync -Aax "$NCDIR" ~/next-backup_$( date "+%y-%m-%d" ) || { echo "Error backup active files"; exit 1; }
sudo mysqldump --lock-tables --default-character-set=utf8mb4 "$DBNAME" > ~/nextcloud-mysql-$( date "+%y-%m-%d" ).sql || { echo "Error backup active db"; exit 1; }

## RE-CREATE DATABASE TABLE

echo "restore database..."
mysql -u root <<EOFMYSQL
DROP DATABASE IF EXISTS nextcloud;
CREATE DATABASE nextcloud
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;
GRANT USAGE ON *.* TO '$DBADMIN'@'localhost' IDENTIFIED BY '$DBPASSWD';
DROP USER '$DBADMIN'@'localhost';
CREATE USER '$DBADMIN'@'localhost' IDENTIFIED BY '$DBPASSWD';
GRANT ALL PRIVILEGES ON nextcloud.* TO $DBADMIN@localhost;
EXIT
EOFMYSQL
[ $? -ne 0 ] && { echo "Error configuring nextcloud database"; exit 1; }

mysql -u root "$DBNAME" <  "$BACKUPDIR"/nextcloud-mysql-dump.sql || { echo "Error restoring nextcloud database"; exit 1; }

## RESTORE DATADIR & FILES

cd "$NCDIR"

# Restore files  
  
#    echo "restore ${NCDIR}/apps"
#    rm -r "${NCDIR}"/apps
#    sudo rsync -Aax "${BACKUPDIR}"/nextcloud/apps/ "$NCDIR"/apps || { echo "Error restoring nextcloud apps"; exit 1; }

	
# Restore Data  
  
  DATADIR=$( grep datadirectory "$NCDIR"/config/config.php | awk '{ print $3 }' | grep -oP "[^']*[^']" | head -1 ) 
  [[ "$DATADIR" == "" ]] && { echo "Error reading data directory"; exit 1; }

  [[ -e "$DATADIR" ]] && { 
    echo "backing up existing $DATADIR"
    mv "$DATADIR" "$DATADIR-$( date "+%y-%m-%d" )" || exit 1
  }

  echo "restore datadir to $DATADIR..."

  mkdir -p "$DATADIR"
  chown www-data:www-data "$DATADIR"

  sudo rsync -Aax "${BACKUPDIR}"/data/ "$DATADIR" || { echo "Error restoring nextcloud datadir"; exit 1; }

# Restore opcache
  
  echo "restore .opcache to $DATADIR..."

sudo rsync -Aax  "$DATADIR-$( date "+%y-%m-%d" )"/.opcache "$DATADIR" || { echo "Error restoring nextcloud .opcache dir"; exit 1; }

# Just in case we moved the opcache dir
sed -i "s|^opcache.file_cache=.*|opcache.file_cache=$DATADIR/.opcache|" /etc/php/${PHPVER}/mods-available/opcache.ini


# tmp upload dir
echo "setting tmp dir...."
mkdir -p "$DATADIR/tmp" 
chown www-data:www-data "$DATADIR/tmp"
sed -i "s|^;\?upload_tmp_dir =.*$|upload_tmp_dir = $DATADIR/tmp|" /etc/php/${PHPVER}/cli/php.ini
sed -i "s|^;\?upload_tmp_dir =.*$|upload_tmp_dir = $DATADIR/tmp|" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s|^;\?sys_temp_dir =.*$|sys_temp_dir = $DATADIR/tmp|"     /etc/php/${PHPVER}/fpm/php.ini

# restore secret for TWO factor auth
echo "setting up 2FA..."
SECRETOLD="$( grep "'secret'" "$NCDIR"/config/config.php )"
SECRETNEW="$( grep "'secret'" "$BACKUPDIR"/nextcloud/config/config.php)"
sed -i "s|$SECRETOLD|$SECRETNEW|"  "$NCDIR"/config/config.php

sudo -u www-data php occ maintenance:mode --off

#
# Afterwork 
#

# NC theme
echo "restore theme..."
IDOLD=$( grep instanceid "$BACKUPDIR"/nextcloud/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")
IDNEW=$( grep instanceid "$NCDIR"/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")

mkdir -p "$DATADIR"/appdata_${IDNEW}/theming/images
cp "$BACKUPDIR"/data/appdata_${IDOLD}/theming/images/logo "$BACKUPDIR"/data/appdata_${IDOLD}/theming/images/background "$DATADIR"/appdata_${IDNEW}/theming/images
chown -R www-data:www-data "$DATADIR"/appdata_${IDNEW}

# Mail config
echo "restore mail config..."

MAILMODE=$( grep mail_smtpmode "$BACKUPDIR"/nextcloud/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")
MAILATYP=$( grep mail_smtpauthtype "$BACKUPDIR"/nextcloud/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")
MAILADD=$( grep mail_from_address "$BACKUPDIR"/nextcloud/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")
MAILDOM=$( grep mail_domain "$BACKUPDIR"/nextcloud/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")
MAILAUTH=$( grep mail_smtpauth "$BACKUPDIR"/nextcloud/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")
MAILHOST=$( grep mail_smtphost "$BACKUPDIR"/nextcloud/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")
MAILSEC=$( grep mail_smtpsecure "$BACKUPDIR"/nextcloud/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")
MAILPORT=$( grep mail_smtpport "$BACKUPDIR"/nextcloud/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")
MAILNAME=$( grep mail_smtpname "$BACKUPDIR"/nextcloud/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")
MAILPASS=$( grep mail_smtppassword "$BACKUPDIR"/nextcloud/config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g")

sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_smtpmode --value="$MAILMODE"
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_smtpauthtype --value="$MAILATYP"
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_from_address --value="$MAILADD"
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_domain       --value="$MAILDOM"
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_domain       --value="$MAILAUTH"
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_domain       --value="$MAILHOST"
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_domain       --value="$MAILSEC"
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_domain       --value="$MAILPORT"
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_domain       --value="$MAILNAME"
sudo -u www-data php /var/www/nextcloud/occ config:system:set mail_domain       --value="$MAILPASS"

#sudo -u www-data php /var/www/nextcloud/occ app:disable twofactor_totp
#sudo -u www-data php /var/www/nextcloud/occ twofactorauth:disable $USRNME

echo "Nextcloud restore finish.

If all is fine you could remove $DATADIR-$( date "+%y-%m-%d" ) 

Please reboot the server!"


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

