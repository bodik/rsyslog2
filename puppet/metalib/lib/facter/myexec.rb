# simple wrapper for custom execs
require "puppet"
module Puppet::Parser::Functions
        newfunction(:myexec, :type => :rvalue) do |args|
                out= Facter::Util::Resolution.exec(args[0])
                if out.nil?
                        return :undef
                else
                        return out
                end
        end
end
