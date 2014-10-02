#!/bin/sh

INDEX="logstash-$(date -u +%Y.%m.%d)"

# this shows ammount of TCP traffic from given/top source addresses
# bq 5 -- netflow/bin/elk_basicquery4.sh -- 
# hive> SELECT sa, sum(ipkt), sum(ibyt) as bytes, count(*) FROM flowdata WHERE pr = "TCP" GROUP BY sa ORDER BY bytes;
curl -XPOST "localhost:39200/${INDEX}/_search?pretty" -d '
{
        "query": { "query_string": { "query": "_type:\"nz\" AND pr:\"TCP\"" } },
	"size": 0,
	"aggs": {
		"group_by_sa": {
			"terms": { 
				"field": "sa", 
				size: 5,
				"order": { "sum_ibyt": "desc" }
			},
			"aggs": {
				"sum_ibyt": { "sum": { "field": "ibyt" } },
				"sum_ipkt": { "sum": { "field": "ipkt" } }
			}
		}
	}
}'




###curl -XPOST "localhost:39200/${INDEX}/_search?pretty" -d '
###{
###	"query" : {
###		"match": { "_type": "nz" }
###        },
###	"size": 5,
###	"aggs": {
###		"group_by_sa": {
###			"terms": { "field": "sa", size: 5 },
###			"aggs": {
###				"sum_ibyt": {
###					"sum": { "field": "ibyt" }
###				},
###				"sum_ipkt": { 
###					"sum": { "field": "ipkt" }
###				}
###			}
###		}
###	}
###}'
###
###echo "========================================================"
###
###curl -XPOST "localhost:39200/${INDEX}/_search?pretty" -d '
###{
###	"query" : {
###        	"filtered": {
###			"query": {
###				"match": { "_type": "nz" }
###			}
###                }
###        },
###	"size": 5,
###	"aggs": {
###		"group_by_sa": {
###			"terms": { "field": "sa", size: 5 },
###			"aggs": {
###				"sum_ibyt": {
###					"sum": { "field": "ibyt" }
###				},
###				"sum_ipkt": { 
###					"sum": { "field": "ipkt" }
###				}
###			}
###		}
###	}
###}'
###
###echo "========================================================"


