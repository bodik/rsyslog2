# simple wrapper for avahi-browse
require "puppet"
module Puppet::Parser::Functions
	newfunction(:avahi_findservice, :type => :rvalue) do |args|
		out= Facter::Util::Resolution.exec('/puppet/metalib/bin/avahi.findservice.sh '+args[0])
		if out.nil?
			return :undef
		else
			return out
		end
	end
end
