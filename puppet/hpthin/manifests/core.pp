#!/usr/bin/puppet apply

## core_tun_number .. number of tunnel, used for networking computations, routing table selection, ...
## thin_public_address .. address of peer
define hpthin::core ($core_tun_number, $thin_public_address) {
	$cmd = "/bin/sh -x /puppet/hpthin/bin/core.sh -n ${core_tun_number} -t ${thin_public_address}"
	notice($cmd)
	exec { "$hashkey creating core tunnel":
		command => "$cmd"
	}
}
