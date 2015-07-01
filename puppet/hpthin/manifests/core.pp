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
		command => "/sbin/ip set dev ${core_tun_dev} up",
	}
	exec { "tunnel address":
		command => "/sbin/ip address ${core_tun_address}/30",
	}
	exec { "route table":
		command => "/bin/echo '${table_num} ${table_name}' >> /etc/iproute2/tables",
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
	Exec["tunnel"]->Exec["tunnel link"]->Exec["tunnel address"]->Exec["route table"]->Exec["route add"]->Exec["route rule"]->Exec["iptables backroute"]
}
