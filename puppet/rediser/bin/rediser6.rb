#!/usr/bin/ruby

require 'hiredis'
require 'timeout'
require 'socket'
require 'logger'
require 'syslog/logger'
require 'optparse'

#require 'ruby-prof'


#############################################app classes

class RediserShutdown < StandardError 
end

class Rediser < Thread
   	def initialize(connection, redis_host, redis_port, redis_key, flush_size, flush_timeout, max_enqueue)
		if $logger then @logger = $logger else @logger = Logger.new(STDOUT) end
		@queue = []
		@conn = nil
		#this comes from old rediser, might be a little bit wired but we'll rework it some other time
		#http://www.regular-expressions.info/posixbrackets.html
		#[:print:] 	Visible characters and spaces (i.e. anything except control characters, etc.) 	[\x20-\x7E]
		#[:cntrl:] 	Control characters 	[\x00-\x1F\x7F] 	
		@allowed_chars = ""
		(32..126).to_a.each { |x| @allowed_chars+=x.chr }
		(0..31).to_a.each { |x| @allowed_chars+=x.chr }
		(127..127).to_a.each { |x| @allowed_chars+=x.chr }

		@connection = connection
		sock_domain, remote_port, remote_hostname, remote_ip = @connection.peeraddr
		@connection_remote_ip = remote_ip
		@connection_remote_port = remote_port

		@redis_host = redis_host
		@redis_port = redis_port
		@redis_key = redis_key
		@flush_size = flush_size
		@flush_timeout = flush_timeout
		@flush_mutex = Mutex.new
		@max_enqueue = [1, max_enqueue - @flush_size].max

		@flush_thread = Thread.new do
			Thread.current["name"] = "flush-#{@connection_remote_ip}-#{@connection_remote_port}"
			@logger.info("flush thread initialized")
		        while sleep(@flush_timeout) do
	        	        flush()
		        end
		end

		@logger.info("rediser thread initialized")

    		super(&method(:thread))
	end
	
	def receive(line)
		@flush_mutex.lock
	        @queue << line
		@flush_mutex.unlock
		
		while (@queue.size >= @flush_size) do flush() end
	end

	def client_close()
		if not @connection.closed? then 
			@connection.close 
			@logger.info("client #{@connection_remote_ip} disconnected")
		end
	end

	def redis_connect()
		begin
			@conn = Hiredis::Connection.new
			@conn.connect(@redis_host, @redis_port)
			@logger.info("connected to redis server #{@conn}")
		rescue Exception => e
			@logger.error("exception #{e}, cannot connect to redis server")
			raise e, "cannot connect to rediser server"
		end
	end

	def flush()
		#debug level is not working well with syslog
		####@logger.debug("rediser flush begin")
		if !@flush_mutex.try_lock # failed to get lock
			####@logger.debug("rediser flush failed to lock mutex")
			return
		end

		begin

			# musim explicitne hlidat delku fronty protoze
			# pipeline write se spatne hlida na chyby
			begin 
				@conn.write ["LLEN", @redis_key]
				l = @conn.read
			end while (l >= @max_enqueue) and @logger.info("rediser sleeping on queue length, qlen #{l}, max_enqueue #{@max_enqueue}") and sleep(3)
	
			@queue.each do |i|
				@conn.write ["RPUSH", @redis_key, i]
			end
			#must read responses from redis server	
			@queue.size.times do
				@conn.read
			end
			@queue.clear

		rescue Exception => e
			@logger.error("exception #{e}, pipeline to redis failed")
			sleep(10)
			#we'll try to reconnect as much as possible, nothing should be raised to flush_thread, rediser_thread should deal with exception by itself
			begin
				redis_connect()
			rescue Exception => e
			end
		end
		@flush_mutex.unlock
		####@logger.debug("rediser flush end")
	end


	def teardown()
		@logger.info("rediser teardown begin #{@queue.size}")
	
		#sure that flusher will not pop deadlock when killed insinde flush()
		@flush_mutex.lock
		@flush_thread.exit
		@flush_thread.join
		@flush_mutex.unlock

		while(@queue.size > 0) do 
			flush()
		end

		@logger.info("rediser teardown end #{@queue.size}")
	end

	def thread()
		#RubyProf.start

		begin
			Thread.current["name"] = "rediser-#{@connection_remote_ip}-#{@connection_remote_port}"
			@logger.info("client #{@connection_remote_ip} connected")

			#if redis connection fails, nothing is read from client, connection is closed and thread ends
			#if read occures druing transfer we at least try to teardown
			redis_connect()
			while line = @connection.gets 
				line = line.tr("^#{@allowed_chars}",'?')
				receive(line)
		    	end
		rescue Exception => e
			@logger.error("exception #{e}, receiving data from client")
		end

		client_close()
		teardown()
		begin
			@conn.disconnect()
		rescue Exception => e
		end

		#RubyProf::FlatPrinter.new(RubyProf.stop).print(STDOUT)
	end
end


class Tlister < Thread
	def initialize(tlisterperiod=60) 
		if $logger then @logger = $logger else @logger = Logger.new(STDOUT) end
		@tlisterperiod = tlisterperiod
    		super(&method(:thread))
	end
	def thread() 
		Thread.current["name"] = "tlister"; 
		while sleep(@tlisterperiod) do 
			Thread.list.select {|th| @logger.info("#{th.inspect}: #{th[:name]}")}

			$tlister_mutex.lock
			begin
				#protoze ruby loop delete
				$threads.delete_if do |th|
					if th.alive?
						false
    					else
						if th.join
							true
						else
							@logger.error("#{th} not joined. should not happen!")
							false
						end
					end
				end
				@logger.info("postgc #{$threads}")
			rescue Exception => e
				@logger.error("exception #{e}")
			end
			$tlister_mutex.unlock
		end 
	end
end




######################################################### init and main

class Interrupted < StandardError; end
#Thread.abort_on_exception=true
Thread.current["name"] = "rediser6-main"
$logger = Logger.new(STDOUT)
# DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
$logger.level = Logger::INFO
$options = {}
$options["redis_host"] = "127.0.0.1"
$options["redis_port"] = 16379
$options["redis_key"] = "r6test"
$options["rediser_port"] = 1234
$options["flush_size"] = 1000
$options["flush_timeout"] = 10
$options["max_enqueue"] = 500000
$options["debug"] = false
$options["tlisterperiod"] = 60
OptionParser.new do |opts|
	opts.banner = "Usage: example.rb [options]"
	opts.on("-l", "--rediser-port PORT", "rediser port") do |v| $options["rediser_port"] = v.to_i end
	opts.on("-r", "--redis-host HOST", "redis host") do |v|	$options["redis_host"] = v end
	opts.on("-p", "--redis-port PORT", "redis port") do |v|	$options["redis_port"] = v.to_i	end
	opts.on("-k", "--redis-key KEY", "redis key to push to") do |v|	$options["redis_key"] = v end
	opts.on("-f", "--flush-size SIZE", "flush x buffered events to redis using pipeline") do |v| $options["flush_size"] = v.to_i end
	opts.on("-t", "--flush-timeout TIMEOUT", "flush at least in x second") do |v| $options["flush_timeout"] = v.to_i end
	opts.on("-m", "--max-enqueue MAX", "maximum redis queue len") do |v| $options["max_enqueue"] = v.to_i end
	opts.on("-x", "--x-lister-perion PERIOD", "tlister period") do |v| $options["tlisterperiod"] = v.to_i end
	opts.on("-s", "--syslog", "log to syslog") do |v| $options["syslog"] = v; $logger = Syslog::Logger.new("rediser6") end
	opts.on("-d", "--debug", "debug mode") do |v| $options["debug"] = v; $logger.level = Logger::DEBUG end
end.parse!
$logger.formatter = proc do |severity, datetime, progname, msg|
	date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
	"[#{date_format}] #{severity} #{Thread.current["name"]}: #{msg}\n"
end
$logger.info("startup options #{$options}")



Signal.trap("INT") { raise RediserShutdown }
Signal.trap("TERM") { raise RediserShutdown }

def shutdown()
	$logger.info("received shutdown")

	$threads.each do |x|
		x.client_close()
		x.join
	end

	$tlister_thread.exit
	$tlister_thread.join

	exit!
end


$threads = []

$tlister_mutex = Mutex.new
$tlister_thread = Tlister.new($options["tlisterperiod"])

begin
	server = TCPServer.new($options["rediser_port"])
	loop do
		begin
	
			connection = server.accept
			connection.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
			$logger.info("accepted connection #{connection}")
			tmp = Rediser.new(connection, $options["redis_host"], $options["redis_port"], $options["redis_key"], $options["flush_size"], $options["flush_timeout"], $options["max_enqueue"])
			$tlister_mutex.lock
			$threads << tmp
			$tlister_mutex.unlock
	
		rescue RediserShutdown => e
			shutdown()
		rescue Exception => e
			$logger.error("exception #{e}, accepting connection")
		end
	end
rescue Exception => e
	$logger.error("exception #{e}, starting server")
end

shutdown()

