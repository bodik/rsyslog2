#!/usr/bin/puppet apply

class hpthin::thinx (
	$key => "1234",

	$thin_tun_dev => "tunx",
	$thin_tun_address => "10.0.0.2",

	$core_public_address => "147.251.253.58",
	$core_tun_address => "10.0.0.1",
) {
	exec { "tunnel":
		command => "/sbin/ip tunnel add ${thin_tun_dev} mode gre local ${ipaddress} remote ${core_public_address} key ${key}",
	}
	exec { "tunnel link":
		command => "/sbin/ip set dev ${thin_tun_dev} up",
	}
	exec { "tunnel address":
		command => "/sbin/ip address ${thin_tun_address}/30 dev ${thin_tun_dev}",
	}
	exec { "iptables redirect":
		command => "/sbin/iptables -t nat -A PREROUTING -p tcp --dport 222 -j DNAT --to-destination ${core_tun_address}:22",
	}
	Exec["tunnel"]->Exec["tunnel link"]->Exec["tunnel address"]->Exec["iptables redirect"]
}
