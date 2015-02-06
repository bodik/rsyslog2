node "elkvut01.ro.vutbr.cz" {
	include metalib::base
	include metalib::fail2ban

	# with rediser
	include rediser
	# esc on secondary interface
	class { "elk::esc":
		network_host =>  $ipaddress_eth0,
	}
	class { "elk::kbn":
	}
}

