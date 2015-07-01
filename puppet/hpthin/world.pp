node "took57.ics.muni.cz" {
#	class { "hpthin::core":
#		key => "1234",
#
#		thin_public_address => "147.251.253.58",
#		thin_tun_address => "10.0.0.2",
#
#		core_tun_dev => "tun01",
#		core_tun_address => "10.0.0.1",
#
#		table_num => "1",
#		table_name => "GW1",
#	}
	class { "hpthin::core":
		key => "1234",

		thin_public_address => "147.251.253.59",
		thin_tun_address => "10.0.0.6",

		core_tun_dev => "tun02",
		core_tun_address => "10.0.0.5",

		table_num => "2",
		table_name => "GW2",
	}
}

node "took58.ics.muni.cz" {
	class { "hpthin::thinx":
		key => "1234",

		thin_tun_dev => "tunx",
		thin_tun_address => "10.0.0.2",
	
		core_public_address => "147.251.253.58",
		core_tun_address => "10.0.0.1",
	}
}

node "took59.ics.muni.cz" {
	class { "hpthin::thinx":
		key => "4321",

		thin_tun_dev => "tunx",
		thin_tun_address => "10.0.0.6",
	
		core_public_address => "147.251.253.59",
		core_tun_address => "10.0.0.5",
	}
}
