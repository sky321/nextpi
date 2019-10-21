#!/bin/sh
IP=$1
APIKEY=xxxxxxxxxxxxx
curl "https://api.ipgeolocation.io/ipgeo?apiKey=${APIKEY}&ip=${IP}&fields=geo&excludes=country_code3,country_code2,zipcode&output=xml"