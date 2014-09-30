#!/bin/sh

INDEX="logstash-$(date -u +%Y.%m.%d)"

# hive> SELECT pr, sa, da, sp, dp, sum(ipkt), sum(ibyt), count(*) FROM flowdata GROUP BY pr, sa, da, sp, dp
curl -XPOST "localhost:39200/${INDEX}/_search?pretty" -d '
{
        "query": { "query_string": { "query": "_type:\"nz\"" } },
	"size": 0,
	"aggs": {
		"group_by_pr": {
			"terms": { "field": "pr", size: 0 },
			"aggs": {
				"group_by_sa": {
					"terms": { "field": "sa", size: 0 },
					"aggs": {
						"group_by_sp": {
							"terms": { "field": "sp", size: 0 },
							"aggs": {
								"group_by_dp": {
									"terms": { "field": "dp", size: 0 },
									"aggs": {
										"sum_ibyt": { "sum": { "field": "ibyt" }},
										"sum_ipkt": { "sum": { "field": "ipkt" }}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}'



