#pulls vals from warden config file

require "puppet"
require "json"
module Puppet::Parser::Functions
        newfunction(:warden_config_dbpassword, :type => :rvalue) do |args|
		out = nil
		begin
			data = JSON.parse(File.read(args[0]))
			#puts data.inspect
			out = data['DB']['password']
		rescue Exception => e
			#none
			#puts e.inspect
		end
                if out.nil?
                        return :undef
                else
                        return out
                end
        end
end
