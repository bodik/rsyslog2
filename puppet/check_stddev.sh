#!/bin/sh 

if [ -f /puppet/PRIVATEFILE_host_$(facter fqdn).pp ]; then
	echo "INFO: puppet apply --modulepath=/puppet -v --noop --show_diff /puppet/PRIVATEFILE_host_$(facter fqdn).pp"
	puppet apply --modulepath=/puppet -v --noop --show_diff /puppet/PRIVATEFILE_host_$(facter fqdn).pp
else
	for all in $(find . -maxdepth 2 -type f -name "*.check.sh"); do
		sh $all
	done
fi
