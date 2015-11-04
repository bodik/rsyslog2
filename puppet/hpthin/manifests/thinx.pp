#!/usr/bin/puppet apply

define hpthin::thinx ($core_tun_number, $core_public_address, $port_forwards) {
	$cmd = "/bin/sh -x /puppet/hpthin/bin/thinx.sh -n ${core_tun_number} -c ${core_public_address} -p ${port_forwards}"
	notice($cmd)
	exec { "$hashkey creating thinx tunnel":
		command => "$cmd"
	}
}
