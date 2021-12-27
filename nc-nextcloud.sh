#!/bin/bash

# Nextcloud installation on Raspbian over LAMP base
#
# Copyleft 2017 by Ignacio Nunez Hernanz <nacho _a_t_ ownyourbits _d_o_t_ com>
# GPL licensed (see end of file) * Use at your own risk!
#
# More at https://ownyourbits.com/2017/02/13/nextcloud-ready-raspberry-pi-image/
#

VER_=$( grep NEXTVER /root/.nextpi.cnf | sed 's|NEXTVER=||' )
BETA_=no

DBADMIN=$( grep DBADMIN /root/.nextpi.cnf | sed 's|DBADMIN=||' )
REDIS_MEM=3gb
PHPVER=$( grep PHPVER /root/.nextpi.cnf | sed 's|PHPVER=||' )
DESCRIPTION="Install any NextCloud version"

APTINSTALL="apt-get install -y --no-install-recommends"
export DEBIAN_FRONTEND=noninteractive

[ -d /var/www/nextcloud ] && {                        # don't show this during image build
INFOTITLE="NextCloud installation"
INFO="This new installation will cleanup current
NextCloud instance, including files and database.

You can later use nc-init to configure to NextCloudPi defaults

** perform backup before proceding **

You can use nc-backup "
}

install()
{
  # During build, this step is run before ncp.sh. Avoid executing twice

  local RELEASE=$( grep RELEASE /root/.nextpi.cnf | sed 's|RELEASE=||' )

  # Optional packets for Nextcloud and Apps
  apt-get update
  $APTINSTALL lbzip2 iputils-ping
  $APTINSTALL -t $RELEASE php${PHPVER}-smbclient                                         # for external storage
  $APTINSTALL -t $RELEASE imagemagick libmagickcore-6.q16-6-extra php${PHPVER}-imagick php${PHPVER}-exif    # for gallery

  # mail
  
  # Install Mailutils with dependencys
  apt-get install -y mailutils  

  # redis

  $APTINSTALL redis-server
  $APTINSTALL -t $RELEASE php${PHPVER}-redis

  local REDIS_CONF=/etc/redis/redis.conf
  local REDISPASS="default"
  sed -i "s|# unixsocket .*|unixsocket /var/run/redis/redis.sock|" $REDIS_CONF
  sed -i "s|# unixsocketperm .*|unixsocketperm 770|"               $REDIS_CONF
  sed -i "s|# requirepass .*|requirepass $REDISPASS|"              $REDIS_CONF
  sed -i 's|# maxmemory-policy .*|maxmemory-policy allkeys-lru|'   $REDIS_CONF
  sed -i 's|# rename-command CONFIG ""|rename-command CONFIG ""|'  $REDIS_CONF
  sed -i "s|^port.*|port 0|"                                       $REDIS_CONF
  echo "maxmemory $REDIS_MEM" >> $REDIS_CONF
  echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf

  usermod -a -G redis www-data

  service redis-server restart
  update-rc.d redis-server enable
  service php${PHPVER}-fpm restart
  
}

configure()
{
  ## IF BETA SELECTED ADD "pre" to DOWNLOAD PATH
  [[ "$BETA_" == yes ]] && local PREFIX="pre"
    
  ## DOWNLOAD AND (OVER)WRITE NEXTCLOUD
  cd /var/www/

  local URL="https://download.nextcloud.com/server/${PREFIX}releases/nextcloud-$VER_.tar.bz2"
  echo "Downloading Nextcloud $VER_..."
  wget -q "$URL" -O nextcloud.tar.bz2 || {
    echo "couldn't download $URL"
    return 1
  }
  rm -rf nextcloud

  echo "Installing  Nextcloud $VER_..."
  tar -xf nextcloud.tar.bz2
  rm nextcloud.tar.bz2

  ## CONFIGURE FILE PERMISSIONS
  local ocpath='/var/www/nextcloud'
  local htuser='www-data'
  local htgroup='www-data'

  printf "Creating possible missing Directories\n"
  mkdir -p $ocpath/data
  mkdir -p $ocpath/updater

  chown -R ${htuser}:${htgroup} ${ocpath}

  # create and configure opcache dir
  local OPCACHEDIR=/var/www/nextcloud/data/.opcache
  sed -i "s|^opcache.file_cache=.*|opcache.file_cache=$OPCACHEDIR|" /etc/php/${PHPVER}/mods-available/opcache.ini
  mkdir -p $OPCACHEDIR
  chown -R www-data:www-data $OPCACHEDIR

  # launch mariadb if not already running (for docker build)
  if ! pgrep -c mariadbd &>/dev/null; then
    echo "Starting mariaDB"
    service mysql start 
  fi

  # wait for mariadb
  pgrep -x mariadbd &>/dev/null || echo "mariaDB process not found"

  while :; do
    [[ -S /var/run/mysqld/mysqld.sock ]] && break
    sleep 0.5
  done


## SET APACHE VHOST
  echo "Setting up Apache..."
  cat > /etc/apache2/sites-available/nextcloud.conf <<'EOF'
<IfModule mod_ssl.c>
  <VirtualHost _default_:443>
    DocumentRoot /var/www/nextcloud
    CustomLog /var/log/apache2/access.log combined
    ErrorLog  /var/log/apache2/error.log
    SSLEngine on
    SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
  </VirtualHost>
  <Directory /var/www/nextcloud/>
    Options +FollowSymlinks
    AllowOverride All
    <IfModule mod_dav.c>
      Dav off
    </IfModule>
    LimitRequestBody 0
    SSLRenegBufferSize 10486000
  </Directory>
</IfModule>
EOF
  a2ensite nextcloud

  cat > /etc/apache2/sites-available/000-default.conf <<'EOF'
<VirtualHost _default_:80>
  DocumentRoot /var/www/nextcloud
  <IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{HTTPS} !=on
    RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L]
  </IfModule>
</VirtualHost>
EOF

  # some added security
  sed -i 's|^ServerSignature .*|ServerSignature Off|' /etc/apache2/conf-enabled/security.conf
  sed -i 's|^ServerTokens .*|ServerTokens Prod|'      /etc/apache2/conf-enabled/security.conf

  echo "Setting up system..."

  ## SET CRON
  echo "*/5  *  *  *  * php -f /var/www/nextcloud/cron.php" > /tmp/crontab_http
  crontab -u www-data /tmp/crontab_http
  rm /tmp/crontab_http
  
  echo "Don't forget to run nc-init"
}

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

