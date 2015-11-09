#!/usr/bin/ruby

require 'hiredis'
require 'logger'
require 'optparse'

class Interrupted < StandardError; end
#Thread.abort_on_exception=true
Thread.current["name"] = "perf_redis_reader.rb"
$logger = Logger.new(STDOUT)
# DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
$logger.level = Logger::INFO
$logger.formatter = proc do |severity, datetime, progname, msg|
	date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
	"[#{date_format}] #{severity} #{Thread.current["name"]}: #{msg}\n"
end
$options = {}
$options["redis_host"] = "127.0.0.1"
$options["redis_port"] = 16379
$options["redis_key"] = "r6test"
$options["batch"] = 1000
OptionParser.new do |opts|
	opts.banner = "Usage: example.rb [options]"
	opts.on("-d", "--debug", "debug") do |v| $options["debug"] = v; $logger.level = Logger::DEBUG end
	opts.on("-i", "--testid ID", "testid") do |v| $options["tid"] = v end
end.parse!

$logger.info("startup options #{$options}")

$count = 0

def teardown()
	date_format = Time.now.strftime("%Y-%m-%d %H:%M:%S")
	puts("[#{date_format}] INFO #{Thread.current["name"]}: RESULT: read #{$count}")
	$stdout.flush
	exit!
end

# Trap ^C 
Signal.trap("INT") { teardown() }
# Trap `Kill `
Signal.trap("TERM") { teardown() }

while true do
	begin
		conn = Hiredis::Connection.new
		conn.connect($options["redis_host"], $options["redis_port"])

		while true do
			#hopefully pipeline read ;)
			(0..$options["batch"]).each do |i|
				begin
					conn.write ["LPOP", $options["redis_key"]]
				rescue => e
					$logger.error(e)
					$logger.error("error sending %s, retry ..." % i)
					sleep 1
					retry
				end
			end
			#must read responses from redise server	
			(0..$options["batch"]).each do
				begin
					a = conn.read
					if a
			        		$logger.debug("read #{a.rstrip()}")
						if a.start_with?("perftestmessage")
							$count = $count + 1
						end
				 	end
				rescue => e
					$logger.error(e)
					$logger.error("error reading pipe response, retry ...")
					sleep 1
					retry
				end
			end

#			#single read
#			conn.write ["LPOP", $options["redis_key"]]
#			a = conn.read
#			if a
#	        		#$logger.debug("read #{a.rstrip()}")
#				$count = $count + 1
#			else
#				sleep(1)
#		 	end


		end

	rescue Exception => e
        	$logger.error("exception #{e}")
		$logger.info("read so far #{$count}")
	end
	sleep(2)
end

