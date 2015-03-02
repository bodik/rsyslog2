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


###qstring = "type:'nz' AND dp:53"
qstring = "type:'nz' AND dp:53 AND pr:\"UDP\""
index = "_all"
query = {
	query: { query_string: { query: qstring } },
	size: 0,
	fields: ["ts", "pr", "sa", "da", "sp", "dp", "ipkt", "ibyt"]
}
puts "BENCHMARK: query basicquery 4 (find some traffic): "+query.to_s
just_search_start = Time.now
client = Elasticsearch::Client.new(log: false, host: Facter.value('ipaddress')+":39200")
just_search_data = client.search(index: index, body: query)
pp just_search_data
just_search_finish = Time.now
diff = just_search_finish - just_search_start
puts "RESULT: query basicquery 4 (find some traffic): "+query.to_s+" took "+diff.to_s+"s"



#scan-scroll
devnull = File.open('/dev/null', 'w')
done = false
i=0

puts "BENCHMARK: query basicquery 4 (scan and scroll): "+query.to_s+", scroll_size="+scroll_size.to_s
start = Time.now

#scan and scroll
# Open the "view" of the index
scroll = client.search(index: index, body: query, search_type: 'scan', scroll: '5m', size: scroll_size)

# Call `scroll` until results are empty
while done !=true 
	
	if debug
		fetchstart = Time.now
	end

	scroll = client.scroll(scroll_id: scroll['_scroll_id'], scroll: '5m')
	if scroll['hits']['hits'].empty?
		done = true
	else
		#just at least touch that data, in case the real read is done on actual usage
		devnull.puts scroll['hits']['hits']
		#puts data['hits']['hits']
	end

	if debug
		fetchstop = Time.now
		diff = fetchstop-fetchstart
		puts "DEBUG: fetch "+i.to_s+" in "+diff.to_s+"s"
		i = i+1
	end

end
finish = Time.now

devnull.close
diff = finish - start
puts "RESULT: query basicquery 4 (scan and scroll): "+query.to_s+", scroll_size="+scroll_size.to_s+" took "+diff.to_s+"s"

