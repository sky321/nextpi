#!/bin/sh
logfile='/var/log/apache2/access.log.1'
echo "-----------------------IP"
sudo awk '{print $1}' ${logfile} | sort | uniq -c
echo "-----------------------IP Resolver"
sudo awk '{print $1}' ${logfile} | sort | uniq | ip2host
echo "-----------------------UserID"
sudo awk '{print $3}' ${logfile} | sort | uniq -c | sort
echo "-----------------------Status code"
sudo awk '{print $9}' ${logfile} | sort | uniq -c
echo "-----------------------Sum Status 40x"
sudo awk '($9 ~ /40/)' ${logfile} | awk '{print $9,$7}' | sort | uniq -c
echo "-----------------------User agent"
sudo awk -F\" '{print $6}' ${logfile} | sort | uniq -c
echo "-----------------------Blank User Agents from"
sudo awk -F\" '($6 ~ /^-?$/)' ${logfile} | awk '{print $1}' | sort | uniq | ip2host
#echo "----------------------Request"
#sudo awk -F\" '{print $2}' ${logfile} | sort | uniq -c | sort
#echo "----------------------What did a special IP?"
#sudo awk '($1 ~ /212.47.226.79/)' ${logfile} | awk '{print $9,$7}' | sort | uniq -c
#echo "-------------------Show request from selected status code"
#sudo awk '($9 ~ 207)' /var/log/apache2/access.log.1 | awk -F\" '{print $2}' | sort | uniq -c

