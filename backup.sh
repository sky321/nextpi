#!/bin/bash

NCDIR=/var/www/nextcloud
DATADIR=$( grep datadirectory "$NCDIR"/config/config.php | awk '{ print $3 }' | grep -oP "[^']*[^']" | head -1 ) 
DBNAME=nextcloud
DBADMIN=$( grep DBADMIN /root/.nextpi.cnf | sed 's|DBADMIN=||' )
DBPASSWD="$( grep password /root/.my.cnf | sed 's|password=||' )"
BACKUPDIR=/mnt/usbstick/next-backup_`date +"%m"`/
CLEANBACK=/mnt/usbstick/next-backup_`date +"%m" --date='2 month ago'`/
PHPVER=$( grep PHPVER /root/.nextpi.cnf | sed 's|PHPVER=||' )
NEWUSER=$( grep PINEWUSER /root/.nextpi.cnf | sed 's|PINEWUSER=||' )
USBDEV=$( grep USBDEV /root/.nextpi.cnf | sed 's|USBDEV=||' )
USBDIR=$( grep USBDIR /root/.nextpi.cnf | sed 's|USBDIR=||' )

echo "----------------------------------"
echo $( date "+%d.%m.%y" )

cd $NCDIR

sudo -u www-data php occ maintenance:mode --on

sudo mount $USBDEV $USBDIR

sudo rsync -Aax $NCDIR $BACKUPDIR
sudo rsync -Aax $DATADIR $BACKUPDIR

sudo rsync -Aax /etc/apache2/sites-available $BACKUPDIR
sudo rsync -Aax /etc/letsencrypt $BACKUPDIR
sudo rsync -Aax /etc/php/${PHPVER}/fpm/php.ini $BACKUPDIR
sudo rsync -Aax /home/${NEWUSER} $BACKUPDIR

sudo mysqldump --single-transaction --default-character-set=utf8mb4 -p$DBPASSWD -u root $DBNAME > "${BACKUPDIR}"/nextcloud-mysql-dump.sql


sudo rm -R -f $CLEANBACK

sudo umount $USBDIR

sudo -u www-data php occ maintenance:mode --off
