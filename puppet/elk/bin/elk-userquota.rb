#!/usr/bin/ruby

# user overquota PoC for portal display

require 'elasticsearch'
require 'pp'

index = Time.now.utc.strftime("logstash-%Y.%m.%d") 

users=File.read("./metausers").split("\n")
user = users[rand(users.length)]

output = Hash.new
output["user"] = users[rand(users.length)]

query = {
	query: { query_string: { query: '_type:"syslog" AND @fields.program:"check_mk.py" AND @fields.message:"'+output["user"]+'"' } },
        sort: '@timestamp',
        size: 9999999
}


client = Elasticsearch::Client.new(log: false, host: "10.0.0.1:39200")
data = client.search(index: index, body: query)

#pp data

data["hits"]["hits"].each do |tmp|
#	puts tmp["_source"]["@fields"]["message"][0]
	if m = tmp["_source"]["@fields"]["message"][0].match(/.*NAGIOS_CUSTOM_CHECK_LOG:QUOTAS: (.*) (.*) (.*)%/)
		c = m.captures
		host = c[0]
		username = c[2]
		size = c[2]
		output["overquota"] = Hash.new if !output["overquota"]
		if !output["overquota"][host]
			output["overquota"][host] = Hash.new
			output["overquota"][host]["size"] = size
			output["overquota"][host]["timestamp"] = tmp["_source"]["@timestamp"]
		end
	end
end

pp output

