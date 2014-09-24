#!/bin/sh

INDEX="logstash-$(date -u +%Y.%m.%d)"

# this shows ammount of number peers for given sa
curl -XPOST "localhost:39200/${INDEX}/_search?pretty" -d '
{
        "query": { "query_string": { "query": "_type:\"nz\" AND sa:147.228.1.133" } },
	"size": 0,
	"aggs": {
		"group_by_sa": {
			"terms": { "field": "sa" },
			"aggs": { 
				"da_count" : {
			            "cardinality" : { "field" : "da" }
                                }
			}
		}
	}
}'

