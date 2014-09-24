#!/bin/sh

INDEX="logstash-$(date -u +%Y.%m.%d)"


#                    { "query_string": { "query": "_type:\"nz\" pr:\"TCP\" AND sa:[147.228.0.0 TO 147.228.255.255]" } }


# this shows ammount of TCP traffic from given/top source addresses
curl -XPOST "localhost:39200/${INDEX}/_search?pretty" -d '
{
	"query": {
                "bool": {
                  "must": [
                    { "query_string": { "query": "_type:\"nz\" pr:\"TCP\"" } }
                  ]
        	}
        },
	"size": 0,
	"aggs": {
		"group_by_sa": {
			"terms": { 
				"field": "sa", 
				size: 5,
				"order": { "sum_ibyt": "desc" }
			},
			"aggs": {
				"sum_ibyt": {
					"sum": { "field": "ibyt" }
				},
				"sum_ipkt": { 
					"sum": { "field": "ipkt" }
				}
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


