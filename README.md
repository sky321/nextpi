- Download Raspbian Image from https://downloads.raspberrypi.org/raspios_lite_arm64/images/
- use Etcher to flash img on SD card https://github.com/balena-io/etcher
- place a file named "ssh" onto the boot partition of the SD card to make ssh available
- for installation via ssh you need to put also a "userconf" file on the card to create a new standard user
	- https://www.raspberrypi.com/news/raspberry-pi-bullseye-update-april-2022/
- boot sd card
- login via ssh with user/password from wizard or userconf
- change language, timezone and keyboard
	- sudo raspi-config
- optional change standard password
	- passwd
- prepare some things upfront
	- curl -s https://raw.githubusercontent.com/sky321/nextpi/master/prep.sh | /bin/bash
- cd nextpi
- change nextpi.cnf (only var above the line are currently used)

------------not needed for newer bullseye versions --------------

- change standard PI user
	- sudo ./chgusr1.sh
	- login as root
	- /home/pi/nextpi/chgusr2.sh
	- login as new user
	
------------not needed for newer bullseye versions --------------
	
- install nextcloud
	- cd nextpi	
	- sudo ./install.sh
- reboot (after reboot the ssh port is changed -> nextpi.cnf)

- optional use nc-restore.sh to restore your data
	- reboot
	- start nextcloud webpage to update if needed
	- cleanup backupdata, data/not_used_appdata, data/not_used_update dir_if_exist
- optional use nc-datadir.sh to move data to a different dir
	- cleanup db entries
	- reboot
- optional use letsencrypt.sh for automated certificates
	- edit fritz.cnf before running the script
	- use base64 for passphrase
- optional replace dhparam.pem with your own values
	- openssl dhparam -out dhparam.pem 4096
	- insert the key in /etc/ssl/certs/dhparam.pem
