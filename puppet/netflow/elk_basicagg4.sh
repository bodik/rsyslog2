#!/bin/sh
#	"query" : {
#        	"filtered": {
#			"match": {
#				 "_type": "nz"
#                    	}
#                }
#        },


INDEX="logstash-$(date +%Y.%m.%d)"




curl -XPOST "localhost:39200/${INDEX}/_search?pretty" -d '
{
	"query" : {
		"match": { "_type": "nz" }
        },
	"size": 5,
	"aggs": {
		"group_by_sa": {
			"terms": { "field": "sa", size: 5 },
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


curl -XPOST "localhost:39200/${INDEX}/_search?pretty" -d '
{
	"query" : {
        	"filtered": {
			"query": {
				"match": { "_type": "nz" }
			}
                }
        },
	"size": 5,
	"aggs": {
		"group_by_sa": {
			"terms": { "field": "sa", size: 5 },
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

