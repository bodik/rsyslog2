#!/usr/bin/ruby

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
        query: { query_string: { query: '_type:"nz"' } },
	size: 0,
	aggs: {
		group_by_sp: {
			terms: { field: "sp", size:20 },
			aggs: {
				group_by_dp: {
					terms: { field: "dp", size:0 },
					aggs: {
						sum_ibyt: { sum: { field: "ibyt" } },
						sum_ipkt: { sum: { field: "ipkt" } }
					}
				}
			}
		}
	}
}


client = Elasticsearch::Client.new(log: false, host: "localhost:39200")
data = client.search(index: index, body: query)

#pp data
#puts sprintf("%10s\t%10s\t%10s", "sp", "dp", "docs" )
puts "["
data["aggregations"]["group_by_sp"]["buckets"].each do |tmpsp|
	tmpsp["group_by_dp"]["buckets"].each do |tmpdp|
		puts sprintf("[%d,%d,%d],", tmpsp["key_as_string"],tmpdp["key_as_string"], tmpdp["doc_count"] )
	end
end
puts "]"
