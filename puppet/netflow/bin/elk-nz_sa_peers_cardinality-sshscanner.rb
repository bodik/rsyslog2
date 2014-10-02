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
        query: { query_string: { query: '_type:"nz" AND dp:22' } },
	size: 0,
	aggs: {
		group_by_sa: {
			terms: { field: "sa", order: { da_card_count: "desc" } },
			aggs: { 
				sum_ibyt: { sum: { field: "ibyt" } },
				sum_ipkt: { sum: { field: "ipkt" } },
				da_card_count: { cardinality: { field: "da" } }
			}
		}
	}
}



client = Elasticsearch::Client.new(log: false, host: "localhost:39200")
data = client.search(index: index, body: query)

#pp data
puts sprintf("%10s\t%10s\t%10s\t%10s\t%10s", "sa", "flows", "sum_ipkt", "sum_ibyt_human", "card" )
data["aggregations"]["group_by_sa"]["buckets"].each do |tmp|
 	puts sprintf("%10s\t%10d\t%10d\t%10s\t%10s", tmp["key_as_string"] , tmp["doc_count"], tmp["sum_ipkt"]["value"], as_size(tmp["sum_ibyt"]["value"]), tmp["da_card_count"]["value"] )
end

