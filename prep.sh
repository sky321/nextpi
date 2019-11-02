#!/bin/bash

## 
#
# Prepare environment for nextpi installation
# curl -s https://raw.githubusercontent.com/sky321/nextpi/master/prep.sh | /bin/bash
#
##

echo
echo
echo "----- change standard password for PI -----"
echo
echo
passwd
echo
echo
echo "----- update the OS -----"
echo
echo
sudo apt-get update -y && sudo apt-get upgrade -y


echo
echo
echo "----- install git -----"
echo
echo
sudo apt-get install -y git

echo
echo
echo "----- get repo from git -----"
echo
echo
git clone https://github.com/sky321/nextpi.git
cd nextpi

echo
echo
echo "----- generate new keys -----"
echo
echo
sudo ./genhostkey.sh