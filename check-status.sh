#!/bin/sh
stat=$1
logfile='/var/log/apache2/access.log.1'

#echo "----------------------Request"
#sudo awk -F\" '{print $2}' ${logfile} | sort | uniq -c | sort

#echo "----------------------What did a special IP?"
#sudo awk '($1 ~ /'$IP'/)' ${logfile} | awk '{print $9,$7}' | sort | uniq -c

echo "-------------------Show request from selected status code"
sudo awk '($9 ~ '$stat')' ${logfile} | awk -F\" '{print $2}' | sort | uniq -c
echo "-------------------"
sudo awk '($9 ~ '$stat')' ${logfile} | sort | uniq -c
