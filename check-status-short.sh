#!/bin/sh
stat=$1
if [ -z "${APACHELOG}" ]; then
     logfile='/var/log/apache2/access.log.1'
     echo "Value is not assigned to a variable"
  else
     logfile=$APACHELOG
     echo "Value is assigned to a variable"
fi

#logfile='/var/log/apache2/access.log.1'

echo "-------------------Show request from selected status code"
sudo awk '($9 ~ '$stat')' ${logfile} | awk -F\" '{print $2}' | sort | uniq -c
