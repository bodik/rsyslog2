#!/usr/bin/puppet apply

class hpthin::core (
	$key = "1234",

	$thin_public_address = "147.251.253.58",
	$thin_tun_address = "10.0.0.2",

	$core_tun_dev = "tun01",
	$core_tun_address = "10.0.0.1",

	$table_num = "1",
	$table_name = "GW1",
) {
	exec { "tunnel":
		command => "/sbin/ip tunnel add ${core_tun_dev} mode gre local ${ipaddress} remote ${thin_public_address} key ${key}",
	}
	exec { "tunnel link":
		command => "/sbin/ip link set dev ${core_tun_dev} up",
	}
	exec { "tunnel address":
		command => "/sbin/ip address add ${core_tun_address}/30 dev ${core_tun_dev}",
		unless => "/sbin/ip addr | /bin/grep ${core_tun_address}",
	}
	exec { "route table":
		command => "/bin/echo '${table_num} ${table_name}' >> /etc/iproute2/rt_tables",
	}
	exec { "route add":
		command => "/sbin/ip route add default table ${table_name} via ${thin_tun_address}",
	}
	exec { "route rule":
		command => "/sbin/ip rule add fwmark ${table_num} table ${table_name}",
	}
	exec { "iptables backroute":
		command => "/sbin/iptables -t mangle -A OUTPUT -s ${core_tun_address} -j MARK --set-mark ${table_num}",
	}
	exec { "ip forwarding":
		command => "/bin/echo 1 > /proc/sys/net/ipv4/ip_forward",
	}
	Exec["tunnel"]->Exec["tunnel link"]->Exec["tunnel address"]->Exec["route table"]->Exec["route add"]->Exec["route rule"]->Exec["iptables backroute"]->Exec["ip forwarding"]
}
