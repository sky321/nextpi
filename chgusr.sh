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
usermod -l $newuser -d /home/${newuser} -m $user

# rename pi group 
groupmod --new-name $newuser $user

# rename user home 
#mv /home/${user} /home/${newuser}

echo "$user was renamed in $newuser

Check su $newuser"