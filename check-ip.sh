#!/bin/sh
IP=$1
logfile='/var/log/apache2/access.log.1'

echo "----------------------What did a special IP?"
sudo awk '($1 ~ /'$IP'/)' ${logfile} | awk '{print $9,$7}' | sort | uniq -c
echo "----------------------"
sudo awk '($1 ~ /'$IP'/)' ${logfile} | sort | uniq -c


