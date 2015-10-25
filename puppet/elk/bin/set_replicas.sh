#!/bin/sh

if [ -z $1 ]; then
        echo "ERROR: no replicas number"
        exit 1
fi


for all in $(curl -s http://localhost:39200/_cat/indices | awk '{print $3}'); do

curl -XPUT "http://localhost:39200/${all}/_settings" -d '
{
    "index" : {
        "number_of_replicas" : '$1'
    }
}
'

done

