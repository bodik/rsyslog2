#!/usr/bin/ruby

# user jobs killed PoC for portal display

require 'elasticsearch'
require 'pp'

index = Time.now.utc.strftime("logstash-%Y.%m.%d") 

users=File.read("./metausers").split("\n")
user = users[rand(users.length)]

output = Hash.new
output["user"] = users[rand(users.length)]

query = {
	query: { query_string: { query: '_type:"syslog" AND @fields.program:"pbs_mom" AND @fields.message:"RESOURCE_KILL" AND @fields.message:"'+output["user"]+'"' } },
        sort: '@timestamp',
        size: 9999999
}


client = Elasticsearch::Client.new(log: false, host: "10.0.0.1:39200")
data = client.search(index: index, body: query)

data["hits"]["hits"].each do |tmp|
	#puts tmp["_source"]["@fields"]["message"][0]
	if m = tmp["_source"]["@fields"]["message"][0].match(/.*LOG_ERROR::Success .* in RESOURCE_KILL, {(.*)} user \[(.*)\].*/)
		c = m.captures
		user = c[0]
		jobid = c[1]
		output["killed"] = Array.new if !output["killed"]
		output["killed"].push(jobid)
	end
end

pp output

