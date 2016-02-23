#!/usr/bin/ruby

#usage ruby elk-misc.rb search 'type:"auth" AND tags:"_grokparsefailure"'

require 'elasticsearch'
require 'pp'
require 'facter'
Facter.loadfacts()


begin
	cmd = ARGV[0]
	qstring = ARGV[1]
	index = Time.now.utc.strftime("logstash-%Y.%m.%d")
	puts "INFO: index: "+index
	puts "INFO: cmd: "+cmd
	puts "INFO: qstring: "+qstring
rescue Exception => e
	puts e.inspect
	puts "ERROR: usage client.rb search|delete qstring"
	exit
end
if Facter.value('ipaddress_eth1')
	addr = Facter.value('ipaddress_eth1')
else
	addr = Facter.value('ipaddress_eth0')
end


query = {
	query: { query_string: { query: qstring } },
}

client = Elasticsearch::Client.new(log: false, host: addr+":39200", transport_options: { request: { timeout: 360 }})

case cmd
	when "search"
		query["fields"] = "message"
		data = client.search(index: index, body: query)
	when "delete"
		data = client.delete_by_query(index: index, body: query)
	else
		puts "cmd not implemented. use search,delete"
end

pp data

