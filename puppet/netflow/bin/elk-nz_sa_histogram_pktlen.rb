#!/usr/bin/ruby

require 'elasticsearch'
require 'pp'

# will print histogram of estimated packet lengths in all traffic for selected node
# pktlen is computed by script
# caveat: packet length (0-64k) != frame size (per phy/mac layer technlogy)

index = Time.now.utc.strftime("logstash-%Y.%m.%d") 
query = {
        query: { query_string: { query: "_type:\"nz\" AND sa:147.251.9.233" } },
	size: 0,
	aggregations: {
        	pktlen_histogram: {
			histogram: {
				script: "doc['ibyt'].value / doc['ipkt'].value",
				interval: 100
			}
		}
	}
}

client = Elasticsearch::Client.new(log: false, host: "localhost:39200")
data = client.search(index: index, body: query)

pp data

