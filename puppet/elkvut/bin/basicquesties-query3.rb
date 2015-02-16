#!/usr/bin/ruby

require 'elasticsearch'
require 'pp'
require 'facter'
Facter.loadfacts()


qstring = "type:'nz' AND dp:53"
index = "_all"

query = {
	query: { query_string: { query: qstring } },
}

puts "BENCHMARK: query basicquery 3 (client.count with query): "+query.to_s

start = Time.now

client = Elasticsearch::Client.new(log: false, host: Facter.value('ipaddress')+":39200")
data = client.count(index: index, body: query)
pp data

finish = Time.now
diff = finish - start
puts "RESULT: query basicquery 3 (client.count with query): "+query.to_s+" took "+diff.to_s+"s"

