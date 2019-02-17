#!/bin/bash

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
NextCloud instance, including files and database.

"


NCDIR=/var/www/nextcloud
BACKUPDIR=/mnt/usbstick/next-backup_## # replace ## with right numbers
USRNME=admin
DBNAME=nextcloud
DBADMIN=ncadmin
DBPASSWD="$( grep password /root/.my.cnf | sed 's|password=||' )"
PHPVER=7.2

cd "$NCDIR"
sudo -u www-data php occ maintenance:mode --on

## BACKUP OLD FILES and DB FILES
echo "backup active files and db..."
#sudo rsync -Aax /var/www/nextcloud ~/next-backup_`date +"%m"`/
sudo rsync -Aax "$NCDIR" ~/next-backup_$( date "+%y-%m-%d" ) || { echo "Error backup active files"; exit 1; }
#sudo mysqldump --lock-tables nextcloud > ~/next-backup_$( date "+%y-%m-%d" )/nextcloud-mysql-dump.sql
sudo mysqldump --lock-tables "$DBNAME" > ~/nextcloud-mysql-$( date "+%y-%m-%d" ).sql || { echo "Error backup active db"; exit 1; }

## RE-CREATE DATABASE TABLE

echo "restore database..."
mysql -u root <<EOFMYSQL
DROP DATABASE IF EXISTS nextcloud;
CREATE DATABASE nextcloud;
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
#    sudo rsync -Aax "${BACKUPDIR}"/owncloud/apps/ "$NCDIR"/apps || { echo "Error restoring nextcloud apps"; exit 1; }

	
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
  sudo -u www-data php occ maintenance:mode --off

# Restore opcache
  
  echo "restore .opcache to $DATADIR..."

# !!!!!!hier unbedingt das gesicherte .opcache dir aus dem ersten Backup der aktiven installation in datadir syncen!!!!!
sudo rsync -Aax  ~/next-backup_$( date "+%y-%m-%d" )/nextcloud/data/.opcache "$DATADIR" || { echo "Error restoring nextcloud .opcache dir"; exit 1; }

# Just in case we moved the opcache dir
sed -i "s|^opcache.file_cache=.*|opcache.file_cache=$DATADIR/.opcache|" /etc/php/${PHPVER}/mods-available/opcache.ini


# tmp upload dir
mkdir -p "$DATADIR/tmp" 
chown www-data:www-data "$DATADIR/tmp"
sed -i "s|^;\?upload_tmp_dir =.*$|upload_tmp_dir = $DATADIR/tmp|" /etc/php/${PHPVER}/cli/php.ini
sed -i "s|^;\?upload_tmp_dir =.*$|upload_tmp_dir = $DATADIR/tmp|" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s|^;\?sys_temp_dir =.*$|sys_temp_dir = $DATADIR/tmp|"     /etc/php/${PHPVER}/fpm/php.ini

#
# Afterwork 
#

#chmod +x permission.sh
#./permission.sh

#sudo -u www-data php /var/www/nextcloud/occ app:disable twofactor_totp
#sudo -u www-data php /var/www/nextcloud/occ twofactorauth:disable $USRNME
echo "disable TWO Factor Auth for all needed User with:

sudo -u www-data php /var/www/nextcloud/occ twofactorauth:disable $USRNME

"

echo "Nextcloud restore finish"


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

