package { ["avahi-daemon", "avahi-utils"]:
	ensure => installed,
}
service { "avahi-daemon": 
	ensure => running,
}

