#!/bin/sh

ESD=$(facter ipaddress_eth1 ipaddress_eth0 | sort -r | awk '{print $3}' | tr '\n' ' ' | awk '{print $1}')
curl -s "http://${ESD}:39200/_cat/indices" | sort --key=3
