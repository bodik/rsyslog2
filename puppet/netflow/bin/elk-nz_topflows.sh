#!/bin/sh

INDEX="logstash-$(date -u +%Y.%m.%d)"

#        "query": { "query_string": { "query": "_type:\"nz\" AND sa:147.228.1.133" } },

# this shows ammount of number peers for given sa which talks to
# caveat: http://www.elasticsearch.org/guide/en/elasticsearch/reference/1.x/search-aggregations-metrics-cardinality-aggregation.html#_counts_are_approximate
curl -XPOST "localhost:39200/${INDEX}/_search?pretty" -d '
{
        "query": { "query_string": { "query": "_type:\"nz\"" } },
	"size": 0,
	"aggs": {
		"group_by_sa": {
			"terms": { 
				"field": "sa",
				"order": { "sum_ibyt": "desc" }
			},
			"aggs": { 
				"sum_ibyt" : { "sum" : { "field" : "ibyt" } }
			}
		}
	}
}'

