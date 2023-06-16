#!/bin/bash

#
# Usage: Before you start check and refine what is to be installed
#
# 

PHPALT=$( grep PHPVER /root/.nextpi.cnf | sed 's|PHPVER=||' )
PHPVER=8.2
DATADIR=$( grep CHGDATADIR /root/.nextpi.cnf | sed 's|CHGDATADIR=||' )
RELEASE=$( grep RELEASE /root/.nextpi.cnf | sed 's|RELEASE=||' )

APTINSTALL="apt-get install -y --no-install-recommends"
export DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get upgrade && apt-get full-upgrade

sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list
sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list.d/*.list
apt-get update

rm /etc/apt/sources.list.d/php.list
rm /etc/apt/preferences.d/php
rm /usr/share/keyrings/deb.sury.org-php.gpg

apt upgrade
apt full-upgrade
head -4 /etc/os-release

# Two currently known quirks may need to be solved:
# 
# The mariadb-server package was left removed instead of upgraded to v10.11.
# The Redis configuration needs to explicitly allow failing to bind on IPv6 now, 
# which previously was implicit. Only relevant if you do not use IPv6, but save to 
# apply in any case.

# apt install mariadb-server
# sed -i '/^bind 127.0.0.1 ::1$/c\bind 127.0.0.1 -::1' /etc/redis/redis.conf
# systemctl restart redis-server

a2dismod php${PHPALT}-fpm
a2enmod php${PHPVER}-fpm
a2disconf php${PHPALT}-fpm
a2enconf php${PHPVER}-fpm
systemctl restart apache2

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

