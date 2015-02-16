#!/usr/bin/ruby

require 'elasticsearch'
require 'pp'
require 'facter'
Facter.loadfacts()

def as_size(s)
  units = %W(B KiB MiB GiB TiB)
  size, unit = units.reduce(s.to_f) do |(fsize, _), utype|
    fsize > 512 ? [fsize / 1024, utype] : (break [fsize, utype])
  end
  "#{size > 9 || size.modulo(1) < 0.1 ? '%d' : '%.1f'} %s" % [size, unit]
end

index = "_all"
query = {
        query: { query_string: { query: '_type:"nz"' } },
	size: 0,
	aggs: {
		sum_ibyt: { sum: { field: "ibyt" } },
		sum_ipkt: { sum: { field: "ipkt" } },
	}
}

puts "BENCHMARK: query basicquery 2 (count, sum_ibyt, sum_ipkt): "+query.to_s

start = Time.now

client = Elasticsearch::Client.new(log: false, host: Facter.value('ipaddress')+":39200")
data = client.search(index: index, body: query)

puts sprintf("count(*)=%d, sum(ipkt)=%d, sum(ibyt)=%d", data['hits']['total'], data['aggregations']['sum_ipkt']['value'], data['aggregations']['sum_ibyt']['value'])

finish = Time.now
diff = finish - start
puts "RESULT: query basicquery 2 (count, sum_ibyt, sum_ipkt): "+query.to_s+" took "+diff.to_s+"s"

