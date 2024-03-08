#!/bin/bash
systemctl start NetworkManager
mac=`nmcli device show ens192|awk '/^GENERAL.HWADDR/ {print $2}'`
ipadress=`nmcli device show ens192|awk  '/^IP4.ADDRESS/ {print $2}'|sed -n '1p'|awk -F/ '{print $1}'`

curl -X PUT -d '{"id": "'$mac'","name": "'$ipadress'","address": "'$ipadress'","port": 9110,"tags": ["'$ipadress'"],"meta": {"job": "'$ipadress'","instance": "'$ipadress'"},"checks": [{"http": "http://'$ipadress':9110/metrics", "interval": "15s"}]}' http://10.0.100.203:8500/v1/agent/service/register

systemctl stop NetworkManager