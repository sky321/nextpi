#!/bin/bash

## Change standard PI user - https://raspberrypi.stackexchange.com/questions/12827/change-default-username
#
# before do: sudo passwd root
#
# login as root user (check /etc/ssh/sshd_config for PermitRootLogin) 
#
# after do: sudo passwd -l root
#
##

user='pi'
newuser='newpi'
rootuser='root'

# rename pi user 
usermod -l $newuser -d /home/${newpiuser} -m $user

# rename pi group 
groupmod --new-name $newuser $user

echo "$user was renamed in $newuser

Check su $newuser"