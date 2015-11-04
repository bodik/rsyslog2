#!/bin/sh

if [ -z $1 ]; then
        echo "ERROR: no rebalance number"
        exit 1
fi

curl -XPUT "http://$(facter ipaddress):39200/_cluster/settings" -d '{"transient":{"cluster.routing.allocation.cluster_concurrent_rebalance": '$1' }}'
curl -XPUT "http://$(facter ipaddress):39200/_cluster/settings" -d '{"transient":{"cluster.routing.allocation.node_concurrent_recoveries": '$1' }}'

