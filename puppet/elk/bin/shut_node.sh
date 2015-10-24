#!/bin/sh

if [ -z $1 ]; then
        echo "ERROR: no node ip"
        exit 1
fi

curl -s -XPUT localhost:39200/_cluster/settings -d '
        {"transient":
                {"cluster.routing.allocation.exclude._ip" :"'$1'"}
        }
'

