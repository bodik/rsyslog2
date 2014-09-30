#!/usr/bin/ruby

require 'elasticsearch'
require 'pp'

index = Time.now.utc.strftime("logstash-%Y.%m.%d") 
query = {
        query: { query_string: { query: "_type:\"nz\" AND sa:147.251.9.233" } },
	size: 0,
	aggregations: {
        	ipktsperflow_ranges: {
			range: {
				field: "ipkt",
				ranges: [
					{ to: 1 },
					{ from: 1, to: 3 },
					{ from: 3, to: 100 },
					{ from: 100, to: 10000 },
					{ from: 10000, to: 100000 },
					{ from: 100000, to: 1000000 },
					{ from: 1000000 }
				
				]
			}
		}
	}
}


client = Elasticsearch::Client.new(log: false, host: "localhost:39200")
data = client.search(index: index, body: query)

pp query
puts sprintf("%s,%s", "range", "number",  )
data["aggregations"]["ipktsperflow_ranges"]["buckets"].each do |tmp|
 	puts sprintf("%20s\t%d", tmp["key"] , tmp["doc_count"])
end

