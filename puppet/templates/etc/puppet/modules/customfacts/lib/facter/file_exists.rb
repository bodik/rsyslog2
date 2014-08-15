#http://www.xenuser.org/downloads/puppet/xenuser_org-010-check_if_file_exists.pp
# This file requires a custom facter script:
#   /etc/puppet/modules/customfacts/lib/facter/file_exists.rb
require "puppet"
module Puppet::Parser::Functions
	newfunction(:file_exists, :type => :rvalue) do |args|
		if File.exists?(args[0])
			return 1
		else
			return 0
		end
	end
end
