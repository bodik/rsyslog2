#!/usr/bin/ruby

require 'elasticsearch'
require 'pp'
require 'facter'
Facter.loadfacts()


debug = false


qstring = "type:'nz' AND pr:\"TCP\""
index = "_all"
query = {
        query: { query_string: { query: qstring } },
        size: 0,
        aggs: {
                group_by_sa: {
                        terms: {
                                field: "sa",
                                size: 0,
                                order: { sum_ibyt: "desc" }
                        },
                        aggs: {
                                sum_ibyt: { sum: { field: "ibyt" } },
                                sum_ipkt: { sum: { field: "ipkt" } }
                        }
                }
        }
}
puts "BENCHMARK: query basicquery 5 (stats for sa): "+query.to_s
just_search_start = Time.now
client = Elasticsearch::Client.new(log: false, host: Facter.value('ipaddress')+":39200")
just_search_data = client.search(index: index, body: query)
pp just_search_data
just_search_finish = Time.now
diff = just_search_finish - just_search_start
puts "RESULT: query basicquery 5 (stats for sa): "+query.to_s+" took "+diff.to_s+"s"



