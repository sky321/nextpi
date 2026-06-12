#!/bin/bash

# Nextcloud LAMP base installation on Raspbian 
#
# Copyleft 2017 by Ignacio Nunez Hernanz <nacho _a_t_ ownyourbits _d_o_t_ com>
# GPL licensed (see end of file) * Use at your own risk!
#
# Usage:
# 
#   ./installer.sh lamp.sh <IP> (<img>)
#
# See installer.sh instructions for details
#
# Notes:
#   Upon each necessary restart, the system will cut the SSH session, therefore
#   it is required to save the state of the installation. See variable $STATE_FILE
#   It will be necessary to invoke this a number of times for a complete installation
#
# More at https://ownyourbits.com/2017/02/13/nextcloud-ready-raspberry-pi-image/
#

PHPVER=$( grep PHPVER /root/.nextpi.cnf | sed 's|PHPVER=||' )
APTINSTALL="apt-get install -y --no-install-recommends"
export DEBIAN_FRONTEND=noninteractive

install()
{
    # GET PHP SOURCES
    ##########################################

    local RELEASE=$( grep RELEASE /root/.nextpi.cnf | sed 's|RELEASE=||' )
    apt-get update
    $APTINSTALL apt-transport-https ca-certificates software-properties-common
    
    # do some apt pinning
#    cat << EOF > /etc/apt/preferences.d/php
#Package: *
#Pin: origin packages.sury.org
#Pin-Priority: -1

#Package: php${PHPVER}-* libapache2-mod-php${PHPVER} libpcre2-* libgd3 libgd-dev
#Pin: origin packages.sury.org
#Pin-Priority: 500
#EOF
    
#    echo "deb https://packages.sury.org/php/ $RELEASE main" > /etc/apt/sources.list.d/php.list
#    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    
#    curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
#    echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $RELEASE main" | sudo tee /etc/apt/sources.list.d/php.list

    # INSTALL 
    ##########################################

    apt-get update
    $APTINSTALL apt-utils cron curl ip2host
    $APTINSTALL apache2

    $APTINSTALL -t $RELEASE php${PHPVER} libapache2-mod-php${PHPVER} php${PHPVER}-curl php${PHPVER}-gd php${PHPVER}-fpm libapache2-mod-fcgid php${PHPVER}-cli php${PHPVER}-opcache \
                            php${PHPVER}-mbstring php${PHPVER}-xml php${PHPVER}-zip php${PHPVER}-common php${PHPVER}-ldap \
                            php${PHPVER}-intl php${PHPVER}-bz2 php${PHPVER}-gmp php${PHPVER}-bcmath 

    mkdir -p /run/php

    # mariaDB password
    local DBPASSWD="default"
    echo -e "[client]\npassword=$DBPASSWD" > /root/.my.cnf
    chmod 600 /root/.my.cnf

    # mariadb install
    $APTINSTALL mariadb-server php${PHPVER}-mysql
    mkdir -p /run/mysqld
    chown mysql /run/mysqld

    # CONFIGURE APACHE 
    ##########################################

  cat >/etc/apache2/conf-available/http2.conf <<EOF
Protocols h2 http/1.1


# HTTP2 configuration
H2Push          on
H2PushPriority  *                       after
H2PushPriority  text/css                before
H2PushPriority  image/jpeg              after   32
H2PushPriority  image/png               after   32
H2PushPriority  application/javascript  interleaved

# SSL/TLS Configuration
SSLProtocol -all +TLSv1.3 +TLSv1.2
SSLCipherSuite EECDH+AESGCM:EDH+AESGCM
SSLOpenSSLConfCmd Curves X25519:secp384r1:prime256v1
SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"
SSLHonorCipherOrder     off
SSLCompression          off
SSLSessionTickets       off

# OCSP Stapling
SSLUseStapling          on
SSLStaplingResponderTimeout 5
SSLStaplingReturnResponderErrors off
SSLStaplingCache        shmcb:logs/ssl_stapling(32768)
EOF

    cat >> /etc/apache2/apache2.conf <<EOF
<IfModule mod_headers.c>
  Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
  Header always set Feature-Policy "accelerometer 'none'; autoplay 'self'; geolocation 'none'; midi 'none'; notifications 'self'; push 'self'; sync-xhr 'self'; microphone 'self'; camera 'self'; magnetometer 'none'; gyroscope 'none'; speaker 'self'; vibrate 'self'; fullscreen 'self'; payment 'none'; usb 'none'"
</IfModule>
EOF

    echo "ServerName localhost" >> /etc/apache2/apache2.conf


    # CONFIGURE PHP
    ##########################################

# Backup old conf files PHP
cp /etc/php/${PHPVER}/fpm/pool.d/www.conf /etc/php/${PHPVER}/fpm/pool.d/www.conf.bak
cp /etc/php/${PHPVER}/fpm/php-fpm.conf /etc/php/${PHPVER}/fpm/php-fpm.conf.bak
cp /etc/php/${PHPVER}/cli/php.ini /etc/php/${PHPVER}/cli/php.ini.bak
cp /etc/php/${PHPVER}/fpm/php.ini /etc/php/${PHPVER}/fpm/php.ini.bak
cp /etc/php/${PHPVER}/mods-available/apcu.ini /etc/php/${PHPVER}/mods-available/apcu.ini.bak
cp /etc/php/${PHPVER}/mods-available/opcache.ini /etc/php/${PHPVER}/mods-available/opcache.ini.bak

# Make conf changes
# https://codeberg.org/criegerde/nextcloud/raw/branch/master/skripte/phpcalc.sh

sed -i "s/;env\[HOSTNAME\] = /env[HOSTNAME] = /" /etc/php/${PHPVER}/fpm/pool.d/www.conf
sed -i "s/;env\[TMP\] = /env[TMP] = /" /etc/php/${PHPVER}/fpm/pool.d/www.conf
sed -i "s/;env\[TMPDIR\] = /env[TMPDIR] = /" /etc/php/${PHPVER}/fpm/pool.d/www.conf
sed -i "s/;env\[TEMP\] = /env[TEMP] = /" /etc/php/${PHPVER}/fpm/pool.d/www.conf
sed -i "s/;env\[PATH\] = /env[PATH] = /" /etc/php/${PHPVER}/fpm/pool.d/www.conf
sed -i 's/pm = dynamic/pm = ondemand/' /etc/php/${PHPVER}/fpm/pool.d/www.conf
sed -i 's/pm.max_children =.*/pm.max_children = 46/' /etc/php/${PHPVER}/fpm/pool.d/www.conf
sed -i 's/pm.start_servers =.*/pm.start_servers = 22/' /etc/php/${PHPVER}/fpm/pool.d/www.conf
sed -i 's/pm.min_spare_servers =.*/pm.min_spare_servers = 15/' /etc/php/${PHPVER}/fpm/pool.d/www.conf
sed -i 's/pm.max_spare_servers =.*/pm.max_spare_servers = 30/' /etc/php/${PHPVER}/fpm/pool.d/www.conf
sed -i "s/;pm.max_requests =.*/pm.max_requests = 1000/" /etc/php/${PHPVER}/fpm/pool.d/www.conf
sed -i "s/allow_url_fopen =.*/allow_url_fopen = 1/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/output_buffering =.*/output_buffering = Off/" /etc/php/${PHPVER}/cli/php.ini
sed -i "s/max_execution_time =.*/max_execution_time = 3600/" /etc/php/${PHPVER}/cli/php.ini
sed -i "s/max_input_time =.*/max_input_time = 3600/" /etc/php/${PHPVER}/cli/php.ini
sed -i "s/post_max_size =.*/post_max_size = 10240M/" /etc/php/${PHPVER}/cli/php.ini
sed -i "s/upload_max_filesize =.*/upload_max_filesize = 10240M/" /etc/php/${PHPVER}/cli/php.ini
sed -i "s/;date.timezone.*/date.timezone = Europe\/\Berlin/" /etc/php/${PHPVER}/cli/php.ini
sed -i "s/;cgi.fix_pathinfo.*/cgi.fix_pathinfo=0/" /etc/php/${PHPVER}/cli/php.ini

sed -i "s/memory_limit = 128M/memory_limit = 1G/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/output_buffering =.*/output_buffering = Off/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/max_execution_time =.*/max_execution_time = 3600/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/max_input_time =.*/max_input_time = 3600/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/post_max_size =.*/post_max_size = 10G/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/upload_max_filesize =.*/upload_max_filesize = 10G/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = Europe\/\Berlin/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo.*/cgi.fix_pathinfo=0/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;session.cookie_secure.*/session.cookie_secure = True/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;opcache.enable=.*/opcache.enable=1/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;opcache.validate_timestamps=.*/opcache.validate_timestamps=1/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;opcache.enable_cli=.*/opcache.enable_cli=1/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;opcache.memory_consumption=.*/opcache.memory_consumption=256/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=64/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=100000/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;opcache.revalidate_freq=.*/opcache.revalidate_freq=0/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;opcache.save_comments=.*/opcache.save_comments=1/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/;opcache.huge_code_pages=.*/opcache.huge_code_pages=0/" /etc/php/${PHPVER}/fpm/php.ini
sed -i "s/session.gc_maxlifetime =.*/session.gc_maxlifetime = 36000/" /etc/php/${PHPVER}/fpm/php.ini

sed -i "s|;emergency_restart_threshold.*|emergency_restart_threshold = 10|g" /etc/php/${PHPVER}/fpm/php-fpm.conf
sed -i "s|;emergency_restart_interval.*|emergency_restart_interval = 1m|g" /etc/php/${PHPVER}/fpm/php-fpm.conf
sed -i "s|;process_control_timeout.*|process_control_timeout = 10|g" /etc/php/${PHPVER}/fpm/php-fpm.conf

sed -i '$aapc.enable_cli=1' /etc/php/8.4/mods-available/apcu.ini

sed -i 's/opcache.jit=off/opcache.jit=on/' /etc/php/${PHPVER}/mods-available/opcache.ini
sed -i '$aopcache.jit=1255' /etc/php/${PHPVER}/mods-available/opcache.ini
sed -i '$aopcache.jit_buffer_size=256M' /etc/php/${PHPVER}/mods-available/opcache.ini

# conf MariaDB for PHP
sed -i '$a[mysql]' /etc/php/${PHPVER}/mods-available/mysqli.ini
sed -i '$amysql.allow_local_infile=On' /etc/php/${PHPVER}/mods-available/mysqli.ini
sed -i '$amysql.allow_persistent=On' /etc/php/${PHPVER}/mods-available/mysqli.ini
sed -i '$amysql.cache_size=2000' /etc/php/${PHPVER}/mods-available/mysqli.ini
sed -i '$amysql.max_persistent=-1' /etc/php/${PHPVER}/mods-available/mysqli.ini
sed -i '$amysql.max_links=-1' /etc/php/${PHPVER}/mods-available/mysqli.ini
sed -i '$amysql.default_port=3306' /etc/php/${PHPVER}/mods-available/mysqli.ini
sed -i '$amysql.connect_timeout=60' /etc/php/${PHPVER}/mods-available/mysqli.ini
sed -i '$amysql.trace_mode=Off' /etc/php/${PHPVER}/mods-available/mysqli.ini

# old conf

#    cat > /etc/php/${PHPVER}/mods-available/opcache.ini <<EOF
#zend_extension=opcache.so
#opcache.enable=1
#opcache.enable_cli=1
#opcache.fast_shutdown=1
#opcache.interned_strings_buffer=64
#opcache.max_accelerated_files=10000
#opcache.memory_consumption=128
#opcache.save_comments=1
#opcache.revalidate_freq=1
#opcache.file_cache=/tmp;
#EOF

# Start modules

    a2enmod http2
    a2enconf http2 
    a2enmod proxy_fcgi setenvif
    a2enconf php${PHPVER}-fpm
    a2enmod rewrite
    a2enmod headers
    a2enmod dir
    a2enmod mime
    a2enmod ssl
    

    # CONFIGURE MarieDB 
    ##########################################

    $APTINSTALL ssl-cert # self signed snakeoil certs


# is this needed ???????
#    cp /etc/mysql/mariadb.conf.d/50-server.cnf         /etc/mysql/mariadb.conf.d/90-ncp.cnf
#    sed -i '/\[mysqld\]/ainnodb_file_per_table=1'      /etc/mysql/mariadb.conf.d/90-ncp.cnf


  # launch mariadb if not already running
  if ! pgrep -c mariadbd &>/dev/null; then
	service mysql start 
  fi

  # wait for mariadb
  while :; do
    [[ -S /run/mysqld/mysqld.sock ]] && break
    sleep 0.5
  done

  cd /tmp
  mysql_secure_installation <<EOF
$DBPASSWD
y
y
$DBPASSWD
$DBPASSWD
y
y
y
y
EOF

# std conf MariaDB

systemctl stop mariadb
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql
mv /etc/mysql/my.cnf /etc/mysql/my.cnf.bak
touch /etc/mysql/my.cnf

cat > /etc/mysql/my.cnf <<EOF
[client]
default-character-set = utf8mb4
port = 3306
socket = /var/run/mysqld/mysqld.sock
[mysqld_safe]
log_error=/var/log/mysql/mysql_error.log
nice = 0
socket = /var/run/mysqld/mysqld.sock
[mysqld]
# performance_schema=ON
basedir = /usr
bind-address = 127.0.0.1
binlog_format = ROW
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci
datadir = /var/lib/mysql
default_storage_engine = InnoDB
expire_logs_days = 2
slave_connections_needed_for_purge = 0
general_log_file = /var/log/mysql/mysql.log
innodb_buffer_pool_size = 1G
innodb_log_buffer_size = 32M
innodb_log_file_size = 512M
innodb_read_only_compressed=OFF
join_buffer_size = 2M
key_buffer_size = 512M
lc_messages_dir = /usr/share/mysql
lc_messages = en_US
log_bin = /var/log/mysql/mariadb-bin
log_bin_index = /var/log/mysql/mariadb-bin.index
log_bin_trust_function_creators = true
log_error = /var/log/mysql/mysql_error.log
log_slow_verbosity = query_plan
log_warnings = 2
long_query_time = 1
max_connections = 100
max_heap_table_size = 64M
max_allowed_packet = 512M
max-binlog-size = 512M
max_binlog_total_size = 2G
myisam_sort_buffer_size = 512M
port = 3306
pid-file = /var/run/mysqld/mysqld.pid
query_cache_limit = 0
query_cache_size = 0
read_buffer_size = 2M
read_rnd_buffer_size = 2M
skip-name-resolve
socket = /var/run/mysqld/mysqld.sock
sort_buffer_size = 2M
table_open_cache = 400
table_definition_cache = 800
tmp_table_size = 32M
tmpdir = /tmp
transaction_isolation = READ-COMMITTED
user = mysql
wait_timeout = 600
[mariadb-dump]
max_allowed_packet = 512M
quick
quote-names
[isamchk]
key_buffer = 16M
EOF

systemctl restart mariadb.service

}

configure() { :; }


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

