
node "took22.ics.muni.cz" {
	hpthin::core { "y":
		core_tun_number => "1",
		thin_public_address => "147.251.253.54",
	}
}

node "took54.ics.muni.cz" {
	hpthin::thinx { "z":
		core_tun_number => "1",
		core_public_address => "147.251.253.22",
		port_forwards => "445,69,3306"
	}
}

