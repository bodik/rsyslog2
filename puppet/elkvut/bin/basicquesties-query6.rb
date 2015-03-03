#!/usr/bin/ruby

require 'elasticsearch'
require 'pp'
require 'facter'
Facter.loadfacts()


agg_size = 5


# hive> SELECT pr, sa, da, sp, dp, sum(ipkt), sum(ibyt), count(*) FROM flowdata GROUP BY pr, sa, da, sp, dp
qstring = "type:'nz'"
index = "_all"
query = {
        query: { query_string: { query: qstring } },
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
client = Elasticsearch::Client.new(log: false, host: Facter.value('ipaddress')+":39200")
just_search_data = client.search(index: index, body: query)
pp just_search_data
just_search_finish = Time.now
diff = just_search_finish - just_search_start
puts "RESULT: query basicquery 6 (stats for various communications): "+query.to_s+" took "+diff.to_s+"s"


