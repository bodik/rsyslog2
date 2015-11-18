require "socket"
require 'hiredis'
require 'logger'
require 'optparse'

class Interrupted < StandardError; end
#Thread.abort_on_exception=true
Thread.current["name"] = "perf_rediser_writer.rb"
$logger = Logger.new(STDOUT)
# DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
$logger.level = Logger::INFO
$options = {}
$options["rediser_host"] = "127.0.0.1"
$options["rediser_port"] = 1234
$options["tid"] = "auto"
$options["count"] = 10
OptionParser.new do |opts|
	opts.banner = "Usage: example.rb [options]"
	opts.on("-c", "--count COUNT", "messages to send") do |v| $options["count"] = v.to_i end
	opts.on("-i", "--testid ID", "testid") do |v| $options["tid"] = v end
	opts.on("-d", "--debug", "debug") do |v| $options["debug"] = v; $logger.level = Logger::DEBUG end
end.parse!
$logger.formatter = proc do |severity, datetime, progname, msg|
	date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
	"[#{date_format}] #{severity} #{Thread.current["name"]}: #{msg}\n"
end
$logger.info("startup options #{$options}")




#perf
beginning_time = Time.now

f = File.open("/dev/urandom","r")

i=0
begin
	s = TCPSocket.open($options["rediser_host"], $options["rediser_port"])
	while i < $options["count"]

		x = f.read(100)
		m = "perftestmessage \\n #{$options["tid"]} tmsg#{i} #{x}\n"

		s.puts m
		$logger.debug(m)
		i = i+1
	end
	s.close
rescue Exception => e
	$logger.error("exception #{e}")
end

f.close()

#perf
end_time = Time.now
$logger.info("count #{$options["count"]} sent #{i} time #{(end_time - beginning_time)} s")
