#!/usr/bin/ruby

require 'hiredis'
require 'timeout'
require 'socket'
require 'logger'
require 'optparse'





#############################################app classes
class Rediser
   	def initialize(connection, redis_host, redis_port, redis_key, flush_size, flush_timeout, max_enqueue)
		if $logger then @logger = $logger else @logger = Logger.new(STDOUT) end

		@queue = []
		@connection = connection
		@redis_host = redis_host
		@redis_port = redis_port
		@redis_key = redis_key
		@flush_size = flush_size
		@flush_timeout = flush_timeout
		@flush_mutex = Mutex.new
		@max_enqueue = max_enqueue - @flush_size

		@flush_thread = Thread.new do
			sock_domain, remote_port, remote_hostname, remote_ip = @connection.peeraddr
			Thread.current["name"] = "flush-#{remote_ip}-#{remote_port}"
			@logger.info("new rediser flush initialized")
		        while sleep(@flush_timeout) do
				@logger.info("rediser flush waked")
	        	        flush()
		        end
		end

		@conn = connect()
		@logger.info("new rediser thread initialized")
	end
	
	def receive(line)
		@logger.debug("rediser receive line: "+line.rstrip())
		@flush_mutex.lock
	        @queue << line
		@flush_mutex.unlock
		
		while (@queue.size >= @flush_size) do
			@logger.info("rediser receive flush")
			flush()
		end
	end

	def connect()
		@logger.info("connecting to redis server")
		conn = Hiredis::Connection.new
		conn.connect(@redis_host, @redis_port)
		@logger.info("connected to redis server #{conn}")
		return conn
	end

	def flush()
		@logger.info("rediser flush")
		if !@flush_mutex.try_lock # failed to get lock
			@logger.warn("rediser flush failed to lock mutex")
			return
		end

		# musim explicitne hlidat delku fronty protoze
		# pipeline write se spatne hlida na chyby
		begin 
			@conn.write ["LLEN", @redis_key]
			l = @conn.read
		end while (l >= @max_enqueue) and sleep(3)

		@queue.each do |i|
			begin
				@conn.write ["RPUSH", @redis_key, i]
			rescue => e
				@logger.error(e)
				@logger.error("error sending %s, retry ..." % i)
				sleep 1
				retry
			end
		end
	
		#must read responses from redise server	
		@queue.size.times do
			begin
				@conn.read
			rescue => e
				@logger.error(e)
				@logger.error("error reading pipe response, retry ...")
				sleep 1
				retry
			end
		end
		@queue.clear

		@flush_mutex.unlock
		@logger.info("rediser flushed")
	end

	def teardown()
		@logger.info("rediser teardown")

		#sure that flusher will not pop deadlock when killed insinde flush()
		@flush_mutex.lock
		@flush_thread.exit
		@flush_thread.join
		@flush_mutex.unlock

		@logger.debug("rediser q size #{@queue.size}")
		while(@queue.size > 0) do 
			flush()
		end
		@logger.info("rediser teardowned")
	end
end


class Tcpserver
	def initialize()
		Thread.current["name"] = "tcpserver"
		if $logger then @logger = $logger else @logger = Logger.new(STDOUT) end
	end
	def run()
		server = TCPServer.new($options["rediser_port"])
		loop do
			t = Thread.start(server.accept) do |connection|
				begin
					sock_domain, remote_port, remote_hostname, remote_ip = connection.peeraddr
					Thread.current["name"] = "tcpsrv-#{remote_ip}-#{remote_port}"

					@logger.info("tcpsrcv: client #{remote_ip} connected")
					rediser = Rediser.new(connection, $options["redis_host"], $options["redis_port"], $options["redis_key"], $options["flush_size"], $options["flush_timeout"], $options["max_enqueue"])
					while line = connection.gets 
						@logger.debug("tcpsrcv: #{connection} received: "+line.rstrip())
						rediser.receive(line)
				    	end
					connection.close
					rediser.teardown()
					@logger.info("tcpsrcv: client #{remote_ip} disconnected")
				rescue  Exception => e
					@logger.error("tcpsrv: exception #{e} rediser #{rediser}")
				end
			end
		end
	end
end


class Tlister
	def initialize() Thread.current["name"] = "tlister"; @logger = $logger end
	def run() while sleep(3) do Thread.list.select {|th| @logger.debug("#{th.inspect}: #{th[:name]}")} end end
end




######################################################### init and main

class Interrupted < StandardError; end
#Thread.abort_on_exception=true
Thread.current["name"] = "rediser6-main"
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
$options["rediser_port"] = 1234
$options["flush_size"] = 1000
$options["flush_timeout"] = 10
$options["max_enqueue"] = 500000
$options["debug"] = false
OptionParser.new do |opts|
	opts.banner = "Usage: example.rb [options]"

	opts.on("-l", "--rediser-port PORT", "rediser port") do |v|
		$options["rediser_port"] = v.to_i
	end
	opts.on("-r", "--redis-host HOST", "redis host") do |v|
		$options["redis_host"] = v
	end
	opts.on("-p", "--redis-port PORT", "redis port") do |v|
		$options["redis_port"] = v.to_i
	end
	opts.on("-k", "--redis-key KEY", "redis key to push to") do |v|
		$options["redis_key"] = v
	end
	opts.on("-f", "--flush-size SIZE", "flush x buffered events to redis using pipeline") do |v|
		$options["flush_size"] = v.to_i
	end
	opts.on("-t", "--flush-timeout TIMEOUT", "flush at least in x second") do |v|
		$options["flush_timeout"] = v.to_i
	end
	opts.on("-m", "--max-enqueue MAX", "maximum redis queue len") do |v|
		$options["max_enqueue"] = v.to_i
	end
	opts.on("-d", "--debug", "debug mode") do |v|
		$options["debug"] = v
		$logger.level = Logger::DEBUG
	end
end.parse!
$logger.info($options)


tlister_thread = Thread.new do
	t = Tlister.new
	t.run()
end

tcpserver_thread = Thread.new do
	t = Tcpserver.new
	t.run()
end

tcpserver_thread.join
tlister_thread.exit
tlister_thread.join


