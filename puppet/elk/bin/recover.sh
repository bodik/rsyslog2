#!/bin/sh
#https://t37.net/how-to-fix-your-elasticsearch-cluster-stuck-in-initializing-shards-mode.html
#when one of two nodes cluster (yes splitbrain) goes away and we want to force shards recovery from replicas

tonode="took2-es01"

curl -s -XGET http://localhost:39200/_cat/shards | grep UNASSIGNED > /tmp/elk.unassignedshards
cat /tmp/elk.unassignedshards | while read line
do
	#echo $line
	index=$(echo $line | awk '{print $1}')
	shard=$(echo $line | awk '{print $2}')

	curl -XPOST 'localhost:39200/_cluster/reroute' -d '
{
	"commands" : [ {
        	"allocate" : {
                 	"index" : "'$index'", 
			"shard" : '$shard',
			"node" : "'$tonode'", 
			"allow_primary" : "true"
		}
	} ]
}'
sleep 1
done

rm /tmp/elk.unassignedshards

