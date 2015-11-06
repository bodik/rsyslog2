#!/usr/bin/ruby

require 'hiredis'
require 'timeout'
require 'socket'

Thread.current["name"] = "main"

require 'logger'
$logger = Logger.new(STDERR)
$logger.level = Logger::DEBUG
$logger.formatter = proc do |severity, datetime, progname, msg|
	date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
	"[#{date_format}] #{severity} #{Thread.current["name"]}: #{msg}\n"
end

# DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
$logger.debug("logger startup DEBUG")
$logger.info("logger startup INFO")
$logger.warn("logger startup WARN")
$logger.error("logger startup ERROR")


class Interrupted < StandardError; end
#Thread.abort_on_exception=true

class Rediser
   	def initialize(connection)
		@logger = $logger
		@queue = []
		@connection = connection

		@redis_host = "127.0.0.1"
		@redis_port = 16379
		@redis_key = "r6test"

		@flush_size = 100000
		@flush_timeout = 3
		@flush_mutex = Mutex.new
		@flush_thread = Thread.new do
			sock_domain, remote_port, remote_hostname, remote_ip = connection.peeraddr
			Thread.current["name"] = "flush-#{remote_ip}-#{remote_port}"
			@logger.debug("new rediser flush initialized")
		        while sleep(@flush_timeout) do
				@logger.debug("rediser flush waked initialized")
	        	        flush()
		        end
		end

		@max_enqueue = 500000 - @flush_size
		@conn = connect()
		
		@logger.debug("new rediser thread initialized")
	end
	
	def receive(line)
		@logger.debug("rediser receive line"+line)
		@flush_mutex.lock
		@logger.debug("rediser mutex locked")
	        @queue << line
		@flush_mutex.unlock
		@logger.debug("rediser mutex unlocked")
		
		while (@queue.size >= @flush_size) do
			flush()
		end
	end

	def connect()
		@logger.info("connecting to redis server")
		conn = Hiredis::Connection.new
		conn.connect(@redis_host, @redis_port)
		@logger.info("connected to redis server "+@conn.inspect)
		return conn
	end

	def flush()
		@logger.debug("rediser flush")
		if !@flush_mutex.try_lock # failed to get lock
			@logger.debug("rediser flush failed to lock mutex")
			return
		end

		# musim explicitne hlidat delku fronty protoze
		# pipeline write se spatne hlida na chyby
		begin 
			@conn.write ["LLEN", @redis_key]
			l = @conn.read
		end while (l >= @max_enqueue) and sleep(1)

		@queue.each do |i|
			begin
				@conn.write ["RPUSH", @redis_key, i]
			rescue => e
				puts "ERROR: error sending %s, retry ..." % i
				sleep 1
				retry
			end
		end
	
		#must read responses from redise server	
		@queue.size.times do
			begin
				@conn.read
			rescue => e
				puts "ERROR: error reading pipe response, retry ..." % i
				sleep 1
				retry
			end
		end
		@queue.clear

		@flush_mutex.unlock
	end

	def teardown()
		@logger.debug("rediser teardown")
		@flush_thread.exit
		@flush_thread.join
		while(@queue.size > 0) do 
			flush()
		end
		@logger.debug("rediser teardowned")
	end
end

class Tlister
	def initialize()
		Thread.current["name"] = "tlister"
		@logger = $logger
	end
	def run()
		while sleep(3) do
			Thread.list.select {|th| @logger.debug("#{th.inspect}: #{th[:name]}")}
	        end
	end
end

class Tcpserver
	def initialize()
		Thread.current["name"] = "tcpserver"
		@logger = $logger
	end
	def run()
		server = TCPServer.new(1234)
		loop do
			t = Thread.start(server.accept) do |connection|
				begin
					sock_domain, remote_port, remote_hostname, remote_ip = connection.peeraddr
					Thread.current["name"] = "tcpsrv-#{remote_ip}-#{remote_port}"
					@logger.info("tcpsrcv: client #{remote_ip} connected")
					rediser = Rediser.new(connection)
					while line = connection.gets 
						@logger.debug("tcpsrcv: #{connection} received: "+line.rstrip())
						rediser.receive(line)
				    	end
					connection.close
					rediser.teardown()
					@logger.info("tcpsrcv: client #{remote_ip} disconnected")
				rescue  Exception => e
					if rediser then
						@logger.debug(rediser)
					end
					@logger.error("tcpsrv: exception #{e} rediser #{rediser}")
				end
			end
		end
	end
end


#akarunner ;)
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

