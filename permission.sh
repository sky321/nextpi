#!/bin/bash

  ## CONFIGURE FILE PERMISSIONS
   ocpath='/var/www/nextcloud'
   htuser='www-data'
   htgroup='www-data'
   rootuser='root'

  printf "Creating possible missing Directories\n"
  mkdir -p $ocpath/data
  mkdir -p $ocpath/updater

  printf "chmod Files and Directories\n"
  find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
  find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750

  printf "chown Directories\n"

  chown -R ${htuser}:${htgroup} ${ocpath}/
  chown -R ${htuser}:${htgroup} ${ocpath}/apps/
  chown -R ${htuser}:${htgroup} ${ocpath}/config/
  chown -R ${htuser}:${htgroup} ${ocpath}/data/
  chown -R ${htuser}:${htgroup} ${ocpath}/themes/
  chown -R ${htuser}:${htgroup} ${ocpath}/updater/

  chmod +x ${ocpath}/occ

  printf "chmod/chown .htaccess\n"
  if [ -f ${ocpath}/.htaccess ]; then
    chmod 0644 ${ocpath}/.htaccess
    chown ${htuser}:${htgroup} ${ocpath}/.htaccess
  fi
  if [ -f ${ocpath}/data/.htaccess ]; then
    chmod 0644 ${ocpath}/data/.htaccess
    chown ${htuser}:${htgroup} ${ocpath}/data/.htaccess
  fi

  # create and configure opcache dir
   OPCACHEDIR=/var/www/nextcloud/data/.opcache
  sed -i "s|^opcache.file_cache=.*|opcache.file_cache=$OPCACHEDIR|" /etc/php/${PHPVER}/mods-available/opcache.ini
  mkdir -p $OPCACHEDIR
  chown -R www-data:www-data $OPCACHEDIR