#!/usr/bin/ruby

#prints out top10 talkers on the network
#
#caveat: by default the information about flow is not aggregated, so for ping
# there will be 2 flows (request, reply )this should be considered in computing
# tops and while doing analytics

require 'elasticsearch'
require 'pp'

def as_size(s)
  units = %W(B KiB MiB GiB TiB)
  size, unit = units.reduce(s.to_f) do |(fsize, _), utype|
    fsize > 512 ? [fsize / 1024, utype] : (break [fsize, utype])
  end
  "#{size > 9 || size.modulo(1) < 0.1 ? '%d' : '%.1f'} %s" % [size, unit]
end

index = Time.now.utc.strftime("logstash-%Y.%m.%d") 
query = {
        query: { query_string: { query: "_type:\"nz\"" } },
        size: 0,
        aggregations: {
                group_by_sa: {
                        terms: { 
                                field: 'sa',
				size: 10,
                                order: { sum_ibyt: 'desc' }
                        },
                        aggregations: { 
                                sum_ibyt: { sum: { field: 'ibyt' } }
                        }
                }
        }
}


client = Elasticsearch::Client.new(log: false, host: "localhost:39200")
data = client.search(index: index, body: query)

#pp data
puts sprintf("%s,%s,%s,%s", "sa", "flows", "sum_ibyt", "sum_ibyt_human"  )
data["aggregations"]["group_by_sa"]["buckets"].each do |tmp|
 	puts sprintf("%s,%d,%d,%s", tmp["key_as_string"] , tmp["doc_count"], tmp["sum_ibyt"]["value"], as_size(tmp["sum_ibyt"]["value"]) )
end

