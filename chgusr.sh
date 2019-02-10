#!/bin/bash

## Change standard PI user - https://raspberrypi.stackexchange.com/questions/12827/change-default-username
#
# Keep in mind that you need to change standard user in fail2ban.sh and syscfg.sh also
#
# before do: sudo passwd root
# 				change /etc/ssh/sshd_config for PermitRootLogin yes
#				/etc/init.d/ssh restart
#
# login as root user (after running chgusr.sh change PermitRootLogin back to #PermitRootLogin)
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

# update sudo  
mv /etc/sudoers.d/010_pi-nopasswd /home/${newuser}
echo "Defaults        !tty_tickets" > /etc/sudoers.d/01_file

# check 
echo "$user was renamed in $newuser

Check su $newuser"