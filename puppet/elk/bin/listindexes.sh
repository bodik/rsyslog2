#!/bin/sh

ESD=$(netstat -nlpa | grep LISTEN | grep :39200 | head -1 | awk '{print $4}')
curl -s "http://${ESD}/_cat/indices" | sort --key=3
