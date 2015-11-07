require "socket"
require 'hiredis'
require 'logger'
require 'optparse'

class Interrupted < StandardError; end
#Thread.abort_on_exception=true
Thread.current["name"] = "perf_rediser_writer.rb"
$logger = Logger.new(STDOUT)
# DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
$logger.level = Logger::DEBUG
$logger.formatter = proc do |severity, datetime, progname, msg|
	date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
	"[#{date_format}] #{severity} #{Thread.current["name"]}: #{msg}\n"
end
$options = {}
$options["rediser_host"] = "127.0.0.1"
$options["rediser_port"] = 1234
$options["tid"] = "auto"
$options["count"] = 10
OptionParser.new do |opts|
	opts.banner = "Usage: example.rb [options]"

	opts.on("-c", "--count COUNT", "messages to send") do |v|
		$options["count"] = v.to_i
	end
	opts.on("-i", "--testid ID", "testid") do |v|
		$options["tid"] = v
	end

end.parse!
$logger.info($options)




#perf
beginning_time = Time.now

i=0
s = TCPSocket.open($options["rediser_host"], $options["rediser_port"])
while i < $options["count"]
	s.puts "#{$options["tid"]} tmsg#{i}\n"
	i = i+1
end
s.close

#perf
end_time = Time.now
$logger.info("perf_rediser_write.rb count #{$options["count"]} sent #{i} time #{(end_time - beginning_time)} s")
