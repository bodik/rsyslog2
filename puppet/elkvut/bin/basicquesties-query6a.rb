#!/usr/bin/ruby

require 'elasticsearch'
require 'pp'
require 'facter'
Facter.loadfacts()


histogram_interval = "5m"
agg_size = 0


def get_agg(timefrom, timeto, agg_size, verbose = false)

	qstring = "type:'nz'"
	index = "_all"
	query = {
	        query: { 
	        	filtered: {
				query: { query_string: { query: qstring }},
				filter: {
		                	range: {
			                    :@timestamp => { gte: timefrom, lt: timeto }
		                	}
		            	}
	        	}
		},
	        size: 0,
	        aggs: {
	                group_by_pr: {
	                        terms: { field: "pr", size: agg_size },
	                        aggs: {
	                                group_by_sa: {
	                                        terms: { field: "sa", size: agg_size },
	                                        aggs: {
	                                                group_by_sp: {
	                                                        terms: { field: "sp", size: agg_size },
	                                                        aggs: {
	                                                                group_by_dp: {
	                                                                        terms: { field: "dp", size: agg_size },
	                                                                        aggs: {
	                                                                                sum_ibyt: { sum: { field: "ibyt" }},
	                                                                                sum_ipkt: { sum: { field: "ipkt" }}
	                                                                        }
	                                                                }
	                                                        }
	                                                }
	                                        }
	                                }
	                        }
	                }
	        }
	}
	puts "BENCHMARK: query basicquery 6 (stats for various communications): "+query.to_s
	just_search_start = Time.now
	client = Elasticsearch::Client.new(log: false, host: Facter.value('ipaddress')+":39200", transport_options: { request: { timeout: 360 }})
	just_search_data = client.search(index: index, body: query)
	pp just_search_data if verbose
	just_search_finish = Time.now
	diff = just_search_finish - just_search_start
	puts "RESULT: query basicquery 6 (stats for various communications): "+query.to_s+" took "+diff.to_s+"s"
	
end


# divide all data into equal bucket because of memory requirements on testing cluster
index = "_all"
query = {
        query: { query_string: { query: '_type:"nz"' } },
	size: 0,
    	aggs: {
	        flows_in_time: { date_histogram: { field: "@timestamp", interval: histogram_interval }}
	    }
}
puts "BENCHMARK: flows_in_time_historgram: "+query.to_s
start = Time.now
client = Elasticsearch::Client.new(log: false, host: Facter.value('ipaddress')+":39200")
data = client.search(index: index, body: query)
finish = Time.now
diff = finish - start
puts "RESULT: flows_in_time_historgram: "+query.to_s+" took "+diff.to_s+"s"
#pp data

#project bucket into ranges
ranges = []
last = "2000-01-01T00:00:00.000Z"
data["aggregations"]["flows_in_time"]["buckets"].each do |tmp|
	if last != tmp["key_as_string"]
		ranges.push( [last,tmp["key_as_string"]] )
	end
	last = tmp["key_as_string"]
end
ranges.push( [last, "2099-01-01T00:00:00.000Z"] )
#pp ranges

# get aggregations for ranges
ranges.each do |tmp|
	get_agg(tmp[0], tmp[1], agg_size)
end

