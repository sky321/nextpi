#!/bin/sh
IP=$1
APIKEY=xxxxxxxxxxxxx
curl -s "https://api.ipgeolocation.io/ipgeo?apiKey=${APIKEY}&ip=${IP}&fields=geo,organization&excludes=country_code3,country_code2,zipcode" | jq .