#!/usr/bin/puppet apply

define hpthin::thinx ($core_tun_number, $core_public_address) {

	$thin_tun_dev = "tunx"

        $core_tun_address_octet = ($core_tun_number*4)+1
        $thin_tun_address_octet = ($core_tun_number*4)+2
	$core_tun_address = "10.0.0.${core_tun_address_octet}"
	$thin_tun_address = "10.0.0.${thin_tun_address_octet}"
	notice($core_tun_address)
	notice($thin_tun_address)
	$hashkey = "$core_tun_number -- $core_public_address"
	notice($hashkey)

	exec { "${hashkey} tunnel del":
		command => "/sbin/ip tunnel del ${thin_tun_dev}",
		onlyif => "/sbin/ip tunnel show | /bin/grep ${thin_tun_dev}",
	}
	exec { "${hashkey} tunnel":
		command => "/sbin/ip tunnel add ${thin_tun_dev} mode gre local ${ipaddress} remote ${core_public_address}",
	}
	exec { "${hashkey} tunnel link":
		command => "/sbin/ip link set dev ${thin_tun_dev} up",
	}
	exec { "${hashkey} tunnel address":
		command => "/sbin/ip address add ${thin_tun_address}/30 dev ${thin_tun_dev}",
		unless => "/sbin/ip addr | /bin/grep ${thin_tun_address}",
	}
	exec { "${hashkey} iptables redirect":
		command => "/sbin/iptables -t nat -A PREROUTING -p tcp --dport 222 -j DNAT --to-destination ${core_tun_address}:22",
	}
	exec { "${hashkey} ip forwarding":
		command => "/bin/echo 1 > /proc/sys/net/ipv4/ip_forward",
	}
	Exec["${hashkey} tunnel del"]->Exec["${hashkey} tunnel"]->Exec["${hashkey} tunnel link"]->Exec["${hashkey} tunnel address"]->Exec["${hashkey} iptables redirect"]->Exec["${hashkey} ip forwarding"]
}
