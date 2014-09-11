# == Class: avahi
#
# Support class for installling avahi utils etc.
#
# === Examples
#
#  class { avahi:
#  }
#
# === Authors
#
# bodik@cesnet.cz
#
class avahi {
	package { ["avahi-daemon", "avahi-utils"]:
	        ensure => installed,
	}
	service { "avahi-daemon":
	        ensure => running,
	}
}
