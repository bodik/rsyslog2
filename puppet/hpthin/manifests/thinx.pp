#!/usr/bin/puppet apply

define hpthin::thinx ($core_tun_number, $core_public_address, $port_forwards) {

	$thin_tun_dev = "tunx"

        $core_tun_address_octet = ($core_tun_number*4)+1
        $thin_tun_address_octet = ($core_tun_number*4)+2
	$core_tun_address = "10.0.0.${core_tun_address_octet}"
	$thin_tun_address = "10.0.0.${thin_tun_address_octet}"

	$hashkey = "$core_tun_number--$core_public_address"
	$cmd = "/bin/sh -x /puppet/hpthin/bin/thinx.sh -d ${thin_tun_dev} -t ${thin_tun_address} -n ${core_tun_number} -c ${core_public_address} -a ${core_tun_address} -p ${port_forwards}"
	notice($hashkey, $cmd)

	exec { "$hashkey creating thinx tunnel":
		command => "$cmd"
	}

}
