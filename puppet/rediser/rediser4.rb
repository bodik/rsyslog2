require 'socket'
require 'hiredis'
require 'timeout'

class Interrupted < StandardError; end

@redis_host = "127.0.0.1"
@redis_port = 16379

if ARGV[0]
	@redis_key = ARGV[0]
else
	@redis_key = "q1"
end

if ARGV[1]
	@flush_size = ARGV[1].to_i
else
	@flush_size = 100000
end

@flush_timeout = 10

@max_enqueue = 500000 - @flush_size

puts "@redis_host: "+@redis_host
puts "@redis_port: "+@redis_port.to_s
puts "@redis_key: "+@redis_key
puts "@flush_size: "+@flush_size.to_s
puts "@flush_timeout: "+@flush_timeout.to_s
puts "@max_enqueue: "+@max_enqueue.to_s



def flush()
	if !@flush_mutex.try_lock # failed to get lock
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



def handle()
  count = 0
  begin
    loop do
      buf = STDIN.readline()

      if buf
	@flush_mutex.lock
        @queue << buf
	@flush_mutex.unlock
      end
      while (@queue.size >= @flush_size) do
		flush()
      end

      count = count + 1
      if (count % 1000000 == 0)
	puts Time.now()
      end

    end # loop do
  rescue => e
    puts("Closing connection", :exception => e, :backtrace => e.backtrace)
  rescue Timeout::Error
    puts("Closing connection after read timeout")
  end # begin

ensure
  begin
    flush()
  rescue IOError
    pass
  end # begin
end





@flush_mutex = Mutex.new
@queue = []
@conn = Hiredis::Connection.new
@conn.connect(@redis_host, @redis_port)
puts "redis connected"

@flush_thread = Thread.new do
	while sleep(@flush_timeout) do
		flush()
        end
end

@work_thread = Thread.new do
	handle()
	while(@queue.size > 0) do 
		flush()
	end
end
@work_thread.join

