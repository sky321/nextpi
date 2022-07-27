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
    echo "deb https://packages.sury.org/php/ $RELEASE main" > /etc/apt/sources.list.d/php.list
	wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg

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
SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1 -TLSv1.2
SSLCipherSuite TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
SSLOpenSSLConfCmd Curves X25519:prime256v1:secp384r1
SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"
SSLHonorCipherOrder     off
SSLCompression          off
SSLSessionTickets       off

# OCSP Stapling
SSLUseStapling          on
SSLStaplingResponderTimeout 5
SSLStaplingReturnResponderErrors off
# SSLStaplingCache        shmcb:/var/run/ocsp(128000)
SSLStaplingCache        shmcb:logs/ssl_stapling(32768)
EOF

    cat >> /etc/apache2/apache2.conf <<EOF
<IfModule mod_headers.c>
  Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
  Header always set Feature-Policy "accelerometer 'none'; autoplay 'self'; geolocation 'none'; midi 'none'; notifications 'self'; push 'self'; sync-xhr 'self'; microphone 'self'; camera 'self'; magnetometer 'none'; gyroscope 'none'; speaker 'self'; vibrate 'self'; fullscreen 'self'; payment 'none'; usb 'none'"
</IfModule>
EOF

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

    a2enmod http2
    a2enconf http2 
    a2enmod proxy_fcgi setenvif
    a2enconf php${PHPVER}-fpm
    a2enmod rewrite
    a2enmod headers
    a2enmod dir
    a2enmod mime
    a2enmod ssl
    
    echo "ServerName localhost" >> /etc/apache2/apache2.conf


    # CONFIGURE LAMP FOR NEXTCLOUD
    ##########################################

    $APTINSTALL ssl-cert # self signed snakeoil certs

    # configure MariaDB ( UTF8 4 byte support )
    cp /etc/mysql/mariadb.conf.d/50-server.cnf         /etc/mysql/mariadb.conf.d/90-ncp.cnf
    #sed -i '/\[mysqld\]/ainnodb_large_prefix=true'     /etc/mysql/mariadb.conf.d/90-ncp.cnf
    sed -i '/\[mysqld\]/ainnodb_file_per_table=1'      /etc/mysql/mariadb.conf.d/90-ncp.cnf
    #sed -i '/\[mysqld\]/ainnodb_file_format=barracuda' /etc/mysql/mariadb.conf.d/90-ncp.cnf


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

