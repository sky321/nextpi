#!/bin/bash -uxe

## 
#
# Prepare environment for nextpi installation
# curl -s https://raw.githubusercontent.com/sky321/nextpi/master/prep.sh | /bin/bash
#
##

echo "----- change standard password for PI -----"
passwd pi

echo "----- update the OS -----"
sudo apt-get update -y && sudo apt-get upgrade -y

echo "----- install git -----"
sudo apt-get install -y git

echo "----- get repo from git -----"
git clone https://github.com/sky321/nextpi.git
cd nextpi

echo "----- generate new keys -----"
sudo ./genhostkey.sh