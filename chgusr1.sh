#!/bin/bash

## Change standard PI user - https://raspberrypi.stackexchange.com/questions/12827/change-default-username
#
# Frist part of the change user process.
# Run as pi user.
# After running this script login as root user and run chgusr2.sh
#
##

# enable root
echo "Set root password"
passwd root

# enable ssh root login
sed -i 's|^#PermitRootLogin .*|PermitRootLogin yes|' /etc/ssh/sshd_config

# restart sshd
/etc/init.d/ssh restart

# put config file in place
rm -f /root/.nextpi.cnf
cp nextpi.cnf /root/.nextpi.cnf
chmod 600 /root/.nextpi.cnf

# after process login as root
echo "Please login as root user!"