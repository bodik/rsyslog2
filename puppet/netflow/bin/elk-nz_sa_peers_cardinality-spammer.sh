#!/bin/sh

INDEX="logstash-$(date -u +%Y.%m.%d)"

# this shows ammount of number peers for given sa which talks to port 25 - trying to find spammer
# caveat: http://www.elasticsearch.org/guide/en/elasticsearch/reference/1.x/search-aggregations-metrics-cardinality-aggregation.html#_counts_are_approximate
curl -XPOST "localhost:39200/${INDEX}/_search?pretty" -d '
{
        "query": { "query_string": { "query": "_type:\"nz\" AND dp:25" } },
	"size": 10,
	"aggs": {
		"group_by_sa": {
			"terms": { "field": "sa", "order": { "da_card_count": "desc" } },
			"aggs": { 
				"sum_ibyt" : { "sum" : { "field" : "ibyt" } },
				"sum_ipkt" : { "sum" : { "field" : "ipkt" } },
				"da_card_count" : { "cardinality" : { "field" : "da" } }
			}

		}
	}
}'

