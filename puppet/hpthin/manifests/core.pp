#!/usr/bin/puppet apply


## core_tun_number .. number of tunnel, used for networking computations, routing table selection, ...
## thin_public_address .. address of peer
define hpthin::core ($core_tun_number, $thin_public_address) {

	$core_tun_dev = "tun${core_tun_number}"
	$table_num = "${core_tun_number}"
	$table_name = "GW${core_tun_number}"

        $core_tun_address_octet = ($core_tun_number*4)+1	
        $thin_tun_address_octet = ($core_tun_number*4)+2
	$core_tun_address = "10.0.0.${core_tun_address_octet}"
	$thin_tun_address = "10.0.0.${thin_tun_address_octet}"
	notice($core_tun_address)
	notice($thin_tun_address)
	$hashkey = "$core_tun_number -- $thin_public_address"
	notice($hashkey)


	exec { "${hashkey} tunnel del":
		command => "/sbin/ip tunnel del ${core_tun_dev}",
		onlyif => "/sbin/ip tunnel show | /bin/grep ${core_tun_dev}",
	}
	exec { "${hashkey} tunnel":
		command => "/sbin/ip tunnel add ${core_tun_dev} mode gre local ${ipaddress} remote ${thin_public_address}",
	}
	exec { "${hashkey} tunnel link":
		command => "/sbin/ip link set dev ${core_tun_dev} up",
	}
	exec { "${hashkey} tunnel address":
		command => "/sbin/ip address add ${core_tun_address}/30 dev ${core_tun_dev}",
		unless => "/sbin/ip addr | /bin/grep ${core_tun_address}",
	}
	exec { "${hashkey} route table":
		command => "/bin/echo '${table_num} ${table_name}' >> /etc/iproute2/rt_tables",
	}
	exec { "${hashkey} route add":
		command => "/sbin/ip route add default table ${table_name} via ${thin_tun_address}",
	}
	exec { "${hashkey} route rule":
		command => "/sbin/ip rule add fwmark ${table_num} table ${table_name}",
	}
	exec { "${hashkey} iptables backroute":
		command => "/sbin/iptables -t mangle -A OUTPUT -s ${core_tun_address} -j MARK --set-mark ${table_num}",
	}
	exec { "${hashkey} ip forwarding":
		command => "/bin/echo 1 > /proc/sys/net/ipv4/ip_forward",
	}
	Exec["${hashkey} tunnel del"]->Exec["${hashkey} tunnel"]->Exec["${hashkey} tunnel link"]->Exec["${hashkey} tunnel address"]->Exec["${hashkey} route table"]->Exec["${hashkey} route add"]->Exec["${hashkey} route rule"]->Exec["${hashkey} iptables backroute"]->Exec["${hashkey} ip forwarding"]
}
