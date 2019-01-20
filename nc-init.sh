#!/bin/bash

# Init NextCloud database and perform initial configuration
#
# Copyleft 2017 by Ignacio Nunez Hernanz <nacho _a_t_ ownyourbits _d_o_t_ com>
# GPL licensed (see end of file) * Use at your own risk!
#
# More at https://ownyourbits.com/2017/02/13/nextcloud-ready-raspberry-pi-image/
#

ADMINUSER_=ncp
ADMINPASS_=ownyourbits
DBADMIN=ncadmin
DESCRIPTION="(Re)initiate Nextcloud to a clean configuration"

INFOTITLE="Clean NextCloud configuration"
INFO="This action will configure NextCloud to NextCloudPi defaults.

** YOUR CONFIGURATION WILL BE LOST **

"

PHPVER=7.2

configure()
{
  echo "Setting up a clean Nextcloud instance... wait until message 'NC init done'"

  # checks
  local REDISPASS=$( grep "^requirepass" /etc/redis/redis.conf  | cut -d' ' -f2 )
  [[ "$REDISPASS" == "" ]] && { echo "redis server without a password. Abort"; return 1; }

  ## RE-CREATE DATABASE TABLE 

  echo "Setting up database..."

  # launch mariadb if not already running
  if ! pgrep -c mysqld &>/dev/null; then
    mysqld & 
  fi

  # wait for mariadb
  pgrep -x mysqld &>/dev/null || { 
    echo "mariaDB process not found. Waiting..."
    while :; do
      [[ -S /run/mysqld/mysqld.sock ]] && break
      sleep 0.5
    done
  }

  # workaround to emulate DROP USER IF EXISTS ..;)
  local DBPASSWD=$( grep password /root/.my.cnf | sed 's|password=||' )
  mysql <<EOF
DROP DATABASE IF EXISTS nextcloud;
CREATE DATABASE nextcloud;
#    CHARACTER SET utf8mb4
#    COLLATE utf8mb4_unicode_ci;
GRANT USAGE ON *.* TO '$DBADMIN'@'localhost' IDENTIFIED BY '$DBPASSWD';
DROP USER '$DBADMIN'@'localhost';
CREATE USER '$DBADMIN'@'localhost' IDENTIFIED BY '$DBPASSWD';
GRANT ALL PRIVILEGES ON nextcloud.* TO $DBADMIN@localhost;
EXIT
EOF

  ## INITIALIZE NEXTCLOUD

  # make sure redis is running first
  if ! pgrep -c redis-server &>/dev/null; then
    mkdir -p /var/run/redis
    chown redis /var/run/redis
    sudo -u redis redis-server /etc/redis/redis.conf &
  fi

  while :; do
    [[ -S /run/redis/redis.sock ]] && break
    sleep 0.5
  done


  echo "Setting up Nextcloud..."

  cd /var/www/nextcloud/
  rm -f config/config.php
  sudo -u www-data php occ maintenance:install --database \
    "mysql" --database-name "nextcloud"  --database-user "$DBADMIN" --database-pass \
    "$DBPASSWD" --admin-user "$ADMINUSER_" --admin-pass "$ADMINPASS_"

  # cron jobs
  sudo -u www-data php occ background:cron

  # redis cache
  sed -i '$d' config/config.php
  cat >> config/config.php <<EOF
  'memcache.local' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' =>
  array (
    'host' => '/var/run/redis/redis.sock',
    'port' => 0,
    'timeout' => 0.0,
    'password' => '$REDISPASS',
  ),
);
EOF

  # tmp upload dir
  local UPLOADTMPDIR=/var/www/nextcloud/data/tmp
  mkdir -p "$UPLOADTMPDIR"
  chown www-data:www-data "$UPLOADTMPDIR"
  sudo -u www-data php occ config:system:set tempdirectory --value "$UPLOADTMPDIR"
  sed -i "s|^;\?upload_tmp_dir =.*$|upload_tmp_dir = $UPLOADTMPDIR|" /etc/php/${PHPVER}/cli/php.ini
  sed -i "s|^;\?upload_tmp_dir =.*$|upload_tmp_dir = $UPLOADTMPDIR|" /etc/php/${PHPVER}/fpm/php.ini
  sed -i "s|^;\?sys_temp_dir =.*$|sys_temp_dir = $UPLOADTMPDIR|"     /etc/php/${PHPVER}/fpm/php.ini


  
  IFACE="$( ip r | grep "default via" | awk '{ print $5 }' | head -1 )"
  IP="$( ip a show dev "$IFACE" | grep global | grep -oP '\d{1,3}(.\d{1,3}){3}' | head -1 )" 
  sudo -u www-data php occ config:system:set trusted_domains 1 --value=$IP
  #sudo -u www-data php occ config:system:set trusted_domains 5 --value="nextcloudpi.local"
  # trusted_domains 6 used by docker
  #sudo -u www-data php occ config:system:set trusted_domains 7 --value="nextcloudpi"
  #sudo -u www-data php occ config:system:set trusted_domains 8 --value="nextcloudpi.lan"

  # email
  sudo -u www-data php occ config:system:set mail_smtpmode     --value="sendmail"
  sudo -u www-data php occ config:system:set mail_smtpauthtype --value="LOGIN"
  sudo -u www-data php occ config:system:set mail_from_address --value="admin"
  sudo -u www-data php occ config:system:set mail_domain       --value="ownyourbits.com"

  # NCP theme
#  [[ -e /usr/local/etc/logo ]] && {
#    local ID=$( grep instanceid config/config.php | awk -F "=> " '{ print $2 }' | sed "s|[,']||g" )
#    [[ "$ID" == "" ]] && { echo "failed to get ID"; return 1; }
#    mkdir -p data/appdata_${ID}/theming/images
#    cp /usr/local/etc/logo /usr/local/etc/background data/appdata_${ID}/theming/images
#    chown -R www-data:www-data data/appdata_${ID}
#  }


  # enable some apps by default
  sudo -u www-data php /var/www/nextcloud/occ app:install calendar
  sudo -u www-data php /var/www/nextcloud/occ app:install contacts
  sudo -u www-data php /var/www/nextcloud/occ app:install notes
  sudo -u www-data php /var/www/nextcloud/occ app:install tasks
  sudo -u www-data php /var/www/nextcloud/occ app:install twofactor_totp
#  sudo -u www-data php /var/www/nextcloud/occ app:install news
#  sudo -u www-data php /var/www/nextcloud/occ app:install admin_notifications
#  sudo -u www-data php /var/www/nextcloud/occ app:install previewgenerator

  sudo -u www-data php /var/www/nextcloud/occ app:enable calendar
  sudo -u www-data php /var/www/nextcloud/occ app:enable contacts
  sudo -u www-data php /var/www/nextcloud/occ app:enable notes
  sudo -u www-data php /var/www/nextcloud/occ app:enable tasks
  sudo -u www-data php /var/www/nextcloud/occ app:enable twofactor_totp
#  sudo -u www-data php /var/www/nextcloud/occ app:enable news
#  sudo -u www-data php /var/www/nextcloud/occ app:enable admin_notifications
#  sudo -u www-data php /var/www/nextcloud/occ app:enable previewgenerator

  # other
  sudo -u www-data php /var/www/nextcloud/occ config:system:set overwriteprotocol --value=https
  sudo -u www-data php /var/www/nextcloud/occ config:system:set lost_password_link --value=disabled
  sudo -u www-data php /var/www/nextcloud/occ config:system:set auth.bruteforce.protection.enabled --value=false --type=boolean
  sudo -u www-data php /var/www/nextcloud/occ config:system:set trashbin_retention_obligation --value="auto, 30"


  echo "NC init done
  
  Login with $ADMINUSER_ and $ADMINPASS_
  "
}

install(){ :; }

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
