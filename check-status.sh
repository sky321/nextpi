#!/bin/sh
stat=$1
logfile='/var/log/apache2/access.log.1'

echo "-------------------Show request from selected status code"
sudo awk '($9 ~ '$stat')' ${logfile} | awk -F\" '{print $2}' | sort | uniq -c
echo "-------------------"
sudo awk '($9 ~ '$stat')' ${logfile} | sort | uniq -c
