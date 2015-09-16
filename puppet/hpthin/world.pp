
node "took59.ics.muni.cz" {
	hpthin::core { "x":
		core_tun_number => "2",
		thin_public_address => "147.251.253.59",
	}

	hpthin::core { "y":
		core_tun_number => "1",
		thin_public_address => "147.251.253.63",
	}
}

node "took63.ics.muni.cz" {
	hpthin::thinx { "z":
		core_tun_number => "1",
		core_public_address => "147.251.253.57",
	}
}

