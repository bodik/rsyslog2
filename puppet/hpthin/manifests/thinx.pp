#!/usr/bin/puppet apply

class hpthin::thinx (
	$key = "1234",

	$thin_tun_dev = "tunx",
	$thin_tun_address = "10.0.0.2",

	$core_public_address = "147.251.253.57",
	$core_tun_address = "10.0.0.1",
) {
	exec { "tunnel":
		command => "/sbin/ip tunnel add ${thin_tun_dev} mode gre local ${ipaddress} remote ${core_public_address} key ${key}",
	}
	exec { "tunnel link":
		command => "/sbin/ip link set dev ${thin_tun_dev} up",
	}
	exec { "tunnel address":
		command => "/sbin/ip address add ${thin_tun_address}/30 dev ${thin_tun_dev}",
		unless => "/sbin/ip addr | /bin/grep ${thin_tun_address}",
	}
	exec { "iptables redirect":
		command => "/sbin/iptables -t nat -A PREROUTING -p tcp --dport 222 -j DNAT --to-destination ${core_tun_address}:22",
	}
	exec { "ip forwarding":
		command => "/bin/echo 1 > /proc/sys/net/ipv4/ip_forward",
	}
	Exec["tunnel"]->Exec["tunnel link"]->Exec["tunnel address"]->Exec["iptables redirect"]->Exec["ip forwarding"]
}
