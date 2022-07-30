#!/bin/bash

## Change standard PI user - https://raspberrypi.stackexchange.com/questions/12827/change-default-username
#
# 2. Part of the change user process
# Run as root user.
# After running login as newuser and process.
# 
##

user=$( grep PIUSER /root/.nextpi.cnf | sed 's|PIUSER=||' )
newuser=$( grep PINEWUSER /root/.nextpi.cnf | sed 's|PINEWUSER=||' )

# rename pi user 
usermod -l $newuser -d /home/${newuser} -m $user

# rename pi group 
groupmod --new-name $newuser $user

# rename user home 
#mv /home/${user} /home/${newuser}

# update sudo  
mv /etc/sudoers.d/010_pi-nopasswd /home/${newuser}
#echo "Defaults        !tty_tickets" > /etc/sudoers.d/01_file

# disable ssh root login and password
sed -i 's|^PermitRootLogin .*|#PermitRootLogin yes|' /etc/ssh/sshd_config
passwd -l root

# check 
echo "$user was renamed in $newuser

Login as $newuser and process!"