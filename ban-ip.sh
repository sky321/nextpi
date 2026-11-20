#!/bin/bash
logfile='/var/log/apache2/access.log.1'

echo "Datei erstellen...."
sudo awk '{print $1}' ${logfile} | sort | uniq -c | awk '{if($1>10)print $2}' > ban-ip.txt

while read ZEILE ; do
        IP=$(echo $ZEILE)
        HOST=$(echo $ZEILE | ip2host)

        if [[ $HOST =~ "vodafone" || $HOST =~ "telefonica" ]];
        then
            echo $IP "---" $HOST 
            echo "Vodafone || Telefonica NOT BANNED"
        else
                echo $IP "---" $HOST
                cscli decision add -i $IP -d 200h
        fi

done < ban-ip.txt
