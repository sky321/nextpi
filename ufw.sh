#!/bin/bash

# Uncomplicated Firewall
#
# Copyleft 2017 by Ignacio Nunez Hernanz <nacho _a_t_ ownyourbits _d_o_t_ com>
# GPL licensed (see end of file) * Use at your own risk!
#
# More at https://ownyourbits.com/2017/02/13/nextcloud-ready-raspberry-pi-image/
#
#
# https://linuxize.com/post/how-to-setup-a-firewall-with-ufw-on-debian-9/
#

SSHPORT=$( grep SSHPORT /root/.nextpi.cnf | sed 's|SSHPORT=||' )
SSHSUBNET=$( grep SSHSUBNET /root/.nextpi.cnf | sed 's|SSHSUBNET=||' )

install()
{
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ufw
  systemctl disable ufw

  # Disable logging to kernel
#  grep -q maxsize /etc/logrotate.d/ufw || sed -i /weekly/a'maxsize 2M' /etc/logrotate.d/ufw

  return 0
}

configure()
{

  ufw --force enable
  systemctl enable ufw
  systemctl start ufw

  echo -e "\n# web server rules"
  ufw allow 80/tcp
  ufw allow 443/tcp

  echo -e "\n# SSH rules"
  ufw allow from $SSHSUBNET to any port $SSHPORT

#  echo -e "\n# DNS rules"
#  ufw allow dns

#  echo -e "\n# SAMBA rules"
#  ufw allow samba

#  echo -e "\n# NFS rules"
#  ufw allow nfs

#  echo -e "\n# UPnP rules"
#  ufw allow proto udp from 192.168.0.0/16

  echo "UFW enabled"
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

