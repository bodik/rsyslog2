#/usr/bin/ruby 
require 'rubygems'
require 'facter'
require 'pp'
Facter.loadfacts()

nodedescription = { 
	fqdn: Facter.value('fqdn'),
	productname: Facter.value('productname'),
	physicalprocessorcount: Facter.value('physicalprocessorcount'),
	processorcount: Facter.value('processorcount'),
	memorytotal: Facter.value('memorytotal'),
	lsbdistdescription: Facter.value('lsbdistdescription'),
	processor0: Facter.value('processor0'),
	proc_mdstat: `cat /proc/mdstat`,
	lshw_system: `lshw -class system`
}

pp nodedescription

