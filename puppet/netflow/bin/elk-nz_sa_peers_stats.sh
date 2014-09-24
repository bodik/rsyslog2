#!/bin/sh

INDEX="logstash-$(date -u +%Y.%m.%d)"

#                    { "query_string": { "query": "_type:\"nz\" pr:\"TCP\" AND sa:[147.228.0.0 TO 147.228.255.255]" } }
#	"query": {
#                "bool": {
#                  "must": [
#                    { "query_string": { "query": "_type:\"nz\" pr:\"TCP\"" } }
#                  ]
#        	}
#        },


# this shows ammount of TCP traffic from given/top source addresses
curl -XPOST "localhost:39200/${INDEX}/_search?pretty" -d '
{
        "query": { "query_string": { "query": "_type:\"nz\" AND sa:147.228.1.133" } },
	"size": 0,
	"aggs": {
		"group_by_sa": {
			"terms": { "field": "sa" },
			"aggs": {
				"group_by_da": {
					"terms": { "field": "da" },
					"aggs" : { 
						"ibyt_stats" : { "extended_stats" : { "field" : "ibyt" } },
					        "ipkt_stats" : { "extended_stats" : { "field" : "ipkt" } },
					        "pr_stats" : { "terms" : { "field" : "pr" } }
					}
				}
			}
		}
	}
}'

