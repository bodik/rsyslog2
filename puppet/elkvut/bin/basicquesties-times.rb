#!/usr/bin/ruby

require 'elasticsearch'
require 'pp'
require 'facter'
Facter.loadfacts()

index = "_all"
query = {
        query: { query_string: { query: '_type:"nz"' } },
	size: 1,
	sort: [ { :@timestamp => { order: 'asc' }}]
}
puts "BENCHMARK: first: "+query.to_s
start = Time.now
client = Elasticsearch::Client.new(log: false, host: Facter.value('ipaddress')+":39200")
data = client.search(index: index, body: query)
pp data
finish = Time.now
diff = finish - start
puts "RESULT: first: "+query.to_s+" took "+diff.to_s+"s"
first_date = DateTime.parse(data["hits"]["hits"][0]["_source"]["@timestamp"])


index = "_all"
query = {
        query: { query_string: { query: '_type:"nz"' } },
	size: 1,
	sort: [ { :@timestamp => { order: 'desc' }}]
}
puts "BENCHMARK: last: "+query.to_s
start = Time.now
client = Elasticsearch::Client.new(log: false, host: Facter.value('ipaddress')+":39200")
data = client.search(index: index, body: query)
pp data
finish = Time.now
diff = finish - start
puts "RESULT: last: "+query.to_s+" took "+diff.to_s+"s"

last_date = DateTime.parse(data["hits"]["hits"][0]["_source"]["@timestamp"])

puts "first "+first_date.to_time.to_i.to_s+" ; last "+last_date.to_time.to_i.to_s



index = "_all"
query = {
        query: { query_string: { query: '_type:"nz"' } },
	size: 0,
    	aggs: {
	        flows_in_time: { date_histogram: { field: "@timestamp", interval: "21m" }}
	    }
}
puts "BENCHMARK: flows_in_time_historgram: "+query.to_s
start = Time.now
client = Elasticsearch::Client.new(log: false, host: Facter.value('ipaddress')+":39200")
data = client.search(index: index, body: query)
pp data
finish = Time.now
diff = finish - start
puts "RESULT: flows_in_time_historgram: "+query.to_s+" took "+diff.to_s+"s"

