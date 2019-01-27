#!/bin/bash

NCDIR=/var/www/nextcloud
DATADIR=$( grep datadirectory "$NCDIR"/config/config.php | awk '{ print $3 }' | grep -oP "[^']*[^']" | head -1 ) 
  [[ "$DATADIR" == "" ]] && { echo "Error reading data directory"; exit 1; }
DBNAME=nextcloud
DBADMIN=ncadmin
DBPASSWD="$( grep password /root/.my.cnf | sed 's|password=||' )"
BACKUPDIR=/mnt/usbstick/next-backup_`date +"%m"`/
CLEANBACK=/mnt/usbstick/next-backup_`date +"%m" --date='3 month ago'`/
PHPVER=7.2

echo "----------------------------------"
echo $( date "+%d.%m.%y" )

cd $NCDIR

sudo -u www-data php occ maintenance:mode --on

sudo rsync -Aax $NCDIR $BACKUPDIR
#sudo rsync -Aax $DATADIR $BACKUPDIR

sudo rsync -Aax /etc/apache2/sites-available $BACKUPDIR
sudo rsync -Aax /etc/letsencrypt $BACKUPDIR
sudo rsync -Aax /etc/php/${PHPVER}/fpm/php.ini $BACKUPDIR

sudo mysqldump --lock-tables -p$DBPASSWD -u root $DBNAME > "${BACKUPDIR}"/nextcloud-mysql-dump.sql

sudo rm -R $CLEANBACK

sudo -u www-data php occ maintenance:mode --off
