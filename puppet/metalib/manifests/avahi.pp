# == Class: avahi
#
# Support class for installling avahi utils and resolving daemon. This class is used
# during dynamic cloud autodiscovery by other classes.
#
# === Examples
#
# include metalib::avahi
#
# === Authors
#
# bodik@cesnet.cz
#
class metalib::avahi ( ) {
	package { ["avahi-daemon", "avahi-utils"]:
	        ensure => installed,
	}
	service { "avahi-daemon": 
		ensure => running, 
		hasstatus => false,
		status    => "/bin/ps ax | grep -v grep | grep avahi-daemon",
	}
}
