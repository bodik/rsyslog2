#!/usr/bin/ruby

require 'hiredis'
require 'logger'

class Interrupted < StandardError; end
#Thread.abort_on_exception=true
Thread.current["name"] = "perf_redis_reader.rb"
$logger = Logger.new(STDOUT)
# DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
$logger.level = Logger::DEBUG
$logger.formatter = proc do |severity, datetime, progname, msg|
	date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
	"[#{date_format}] #{severity} #{Thread.current["name"]}: #{msg}\n"
end

redis_host = "127.0.0.1"
redis_port = 16379
redis_key = "r6test"

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
		conn.connect(redis_host, redis_port)
		while true do
			conn.write ["LPOP", redis_key]
			a = conn.read
			if a
	        		$logger.debug("read #{a.rstrip()}")
				$count = $count + 1
			else
				sleep(1)
		 	end
		end
	rescue Exception => e
        	$logger.error("exception #{e}")
		$logger.info("read so far #{$count}")
	end
	sleep(2)
end

