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
class metalib::avahi {
	package { ["avahi-daemon", "avahi-utils"]:
	        ensure => installed,
	}
	service { "avahi-daemon":
	        ensure => running,
	}
	file { "/usr/local/bin/avahi.findservice.sh":
	        ensure => link,
        	target => "/puppet/metalib/avahi.findservice.sh",
	}
}
