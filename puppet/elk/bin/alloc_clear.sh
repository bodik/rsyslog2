#!/bin/sh

curl -s -XPUT localhost:39200/_cluster/settings -d '
	{"persistent":{},"transient":{"cluster":{"routing":{"allocation":{"exclude":{"_ip":""},"include":{}}}}}}
'

