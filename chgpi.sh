#!/bin/bash

## Change standard PI user - https://raspberrypi.stackexchange.com/questions/12827/change-default-username
#
# before do: sudo passwd root
#
# after do: sudo passwd -l root
#
# login as root user (check /etc/ssh/sshd_config for PermitRootLogin) 
##

piuser='pi'
newpiuser='newpi'
rootuser='root'

# rename pi user 
usermod -l $newpiuser -d /home/${newpiuser} -m $piuser

# rename pi group 
groupmod --new-name $newpiuser $piuser

echo "$piuser was renamed in $newpiuser

Check su $newpiuser"