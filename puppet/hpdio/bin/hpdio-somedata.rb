#!/usr/bin/ruby

require 'elasticsearch'
require 'pp'
require 'facter'
Facter.loadfacts()


scroll_size = 5000
debug = false
if ARGV[0]
	scroll_size = ARGV[0].to_i
end
if Facter.value('ipaddress_eth1')
	addr = Facter.value('ipaddress_eth1')
else
	addr = Facter.value('ipaddress_eth0')
end


qstring = "type:'wb' AND Node.SW:'Dionaea' AND NOT Category:'Recon.Scanning'"
index = "_all"
query = {
	query: { query_string: { query: qstring } },
	size: 9999,
	sort: "Attach.datalen"
}
puts "BENCHMARK: meta: "+query.to_s
just_search_start = Time.now
client = Elasticsearch::Client.new(log: false, host: addr+":39200", transport_options: { request: { timeout: 360 }})
just_search_data = client.search(index: index, body: query)

#pp just_search_data
just_search_data['hits']['hits'].each do |x|
	#puts x
	puts [
		x["_source"]["DetectTime"],
		x["_source"]["Source"]["hostname"],
		x["_source"]["Category"],
		x["_source"]["Attach"]
	].join(" ")
end

just_search_finish = Time.now
diff = just_search_finish - just_search_start
puts "RESULT: meta: "+query.to_s+" took "+diff.to_s+"s"

