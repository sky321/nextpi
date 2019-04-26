#!/bin/bash

# NextCloudPi additions to Raspbian 
#
# Copyleft 2017 by Ignacio Nunez Hernanz <nacho _a_t_ ownyourbits _d_o_t_ com>
# GPL licensed (see end of file) * Use at your own risk!
#
# More at https://nextcloudpi.com
#

export DEBIAN_FRONTEND=noninteractive
HOST=$( grep HOST /root/.nextpi.cnf | sed 's|HOST=||' )

configure()
{
  
## SET CRON for Backup Job
  echo "init backup cronjob...."
  echo "0 22 * * 5 sh /home/sky/nextpi/backup.sh >> /var/log/backup.log 2>&1" > /tmp/crontab_backup
  crontab -u root /tmp/crontab_backup
  rm /tmp/crontab_backup

  # automount USB drive after reboot
  echo "automount USB...."
  echo "UUID=1b18feab-3afd-46f8-8fa0-9b2c45ab0abe /mnt/usbstick ext4 defaults,rw 0    0" >> /etc/fstab
  
  # Initiat logrotate
  echo "init logrotate...."

  cat >> /etc/logrotate.d/unattended-upgrades <<'EOF'
/var/log/unattended-upgrades/unattended-upgrades.log
{
  rotate 6
  monthly
  compress
  missingok
  notifempty
	postrotate
        	rm /var/log/unattended-upgrades/unattended-upgrades-dpkg_*;
	endscript
}
EOF

#  cat >> /etc/logrotate.d/letsencrypt <<'EOF'
#/var/log/letsencrypt/letsencrypt.log
#{
#  rotate 14 
#  daily
#  compress
#  missingok
#  notifempty
#}
#EOF

    # SSH hardening
    echo "SSH hardnening...."

    if [[ -f /etc/ssh/sshd_config ]]; then
      sed -i 's|^#AllowTcpForwarding .*|AllowTcpForwarding no|'     /etc/ssh/sshd_config 
      sed -i 's|^#ClientAliveCountMax .*|ClientAliveCountMax 2|'    /etc/ssh/sshd_config
      sed -i 's|^MaxAuthTries .*|MaxAuthTries 1|'                   /etc/ssh/sshd_config
      sed -i 's|^#MaxSessions .*|MaxSessions 2|'                    /etc/ssh/sshd_config
      sed -i 's|^#TCPKeepAlive .*|TCPKeepAlive no|'                 /etc/ssh/sshd_config
      sed -i 's|^X11Forwarding .*|X11Forwarding no|'                /etc/ssh/sshd_config
      sed -i 's|^#LogLevel .*|LogLevel VERBOSE|'                    /etc/ssh/sshd_config
      sed -i 's|^#Compression .*|Compression no|'                   /etc/ssh/sshd_config
      sed -i 's|^#AllowAgentForwarding .*|AllowAgentForwarding no|' /etc/ssh/sshd_config
      sed -i 's|^#Port .*|Port 10317|'                              /etc/ssh/sshd_config
      sed -i 's|^#PermitRootLogin .*|PermitRootLogin no|'          /etc/ssh/sshd_config
    fi

    ## kernel hardening
    echo "kernel hardnening...."

    cat >> /etc/sysctl.conf <<EOF
fs.protected_hardlinks=1
fs.protected_symlinks=1
kernel.core_uses_pid=1
kernel.dmesg_restrict=1
kernel.kptr_restrict=2
kernel.sysrq=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.conf.default.log_martians=1
net.ipv4.tcp_timestamps=0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.tcp_syncookies = 1
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
EOF


## Hostname replacement 
  echo "replace Hostname...."
  echo $HOST > /etc/hostname
  sed -i "s|raspberrypi|$HOST|"  /etc/hosts
  
}

install() { :; }


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
