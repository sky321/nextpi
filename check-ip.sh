#!/bin/sh
IP=$1
if [ -z "${APACHELOG}" ]; then
     logfile='/var/log/apache2/access.log.1'
     echo "Value is not assigned to a variable"
  else
     logfile=$APACHELOG
     echo "Value is assigned to a variable"
fi

#logfile='/var/log/apache2/access.log.1'
echo "----------------------What did a special IP?"
sudo awk '($1 ~ /'$IP'/)' ${logfile} | awk '{print $9,$7}' | sort | uniq -c
echo "----------------------"
sudo awk '($1 ~ /'$IP'/)' ${logfile} | sort | uniq -c


