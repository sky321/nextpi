#!/bin/sh
IP=$1
APIKEY=xxxxxxxxxxxxx
curl "https://api.ipgeolocation.io/ipgeo?apiKey=${APIKEY}&ip=${IP}&fields=geo&output=xml"
