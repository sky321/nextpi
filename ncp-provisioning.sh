#!/bin/bash

# this script runs at startup to provide an unique random passwords for each instance

## redis provisioning

CFG=/var/www/nextcloud/config/config.php
CONFDIR=/usr/local/etc/ncp-config.d/
REDISPASS="$( grep "^requirepass" /etc/redis/redis.conf | cut -f2 -d' ' )"

### IF redis password is the default one, generate a new one

[[ "$REDISPASS" == "default" ]] && {
  REDISPASS="$( openssl rand -base64 32 )"
  echo Provisioning Redis password
  sed -i -E "s|^requirepass .*|requirepass $REDISPASS|" /etc/redis/redis.conf
  [[ "$DOCKERBUILD" != 1 ]] && systemctl restart redis
}

### If there exists already a configuration adjust the password
[[ -f "$CFG" ]] && {
  echo "Updating NextCloud config with Redis password"
  sed -i "s|'password'.*|'password' => '$REDISPASS',|" "$CFG"
}

## mariaDB provisioning

DBADMIN=$( grep DBADMIN /root/.nextpi.cnf | sed 's|DBADMIN=||' )
DBPASSWD=$( grep password /root/.my.cnf | sed 's|password=||' )

[[ "$DBPASSWD" == "default" ]] && {
  DBPASSWD=$( openssl rand -base64 32 )
  echo Provisioning MariaDB password
  echo -e "[client]\npassword=$DBPASSWD" > /root/.my.cnf
  chmod 600 /root/.my.cnf
  mysql <<EOF
GRANT USAGE ON *.* TO '$DBADMIN'@'localhost' IDENTIFIED BY '$DBPASSWD';
DROP USER '$DBADMIN'@'localhost';
CREATE USER '$DBADMIN'@'localhost' IDENTIFIED BY '$DBPASSWD';
GRANT ALL PRIVILEGES ON nextcloud.* TO $DBADMIN@localhost;
FLUSH PRIVILEGES;
EXIT
EOF
}

[[ -f "$CFG" ]] && {
  echo "Updating NextCloud config with MariaDB password"
  sed -i "s|'dbpassword' =>.*|'dbpassword' => '$DBPASSWD',|" "$CFG"
}



exit 0
