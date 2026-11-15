#!/bin/bash
apt-get update
apt-get dist-upgrade
apt-get autoremove
apt-get clean
#sudo rpi-update
#sudo unattended-upgrade -d