# == Class: metalib::fail2ban
#
# Class for installling fail2ban. Used during phase2 eg. basic machine
# setting.
#
# === Examples
#
#  include metalib::fail2ban
#
class metalib::fail2ban () {
	notice($name)
	package { "fail2ban":
		ensure => installed,
	}
	service { "fail2ban":
		ensure => running,
	}

	file { "/etc/fail2ban/fail2ban.local":
		source => "puppet:///modules/${module_name}/etc/fail2ban/fail2ban.local",
		owner => "root", group=>"root", mode=>"0644",
		require => Package["fail2ban"],
		notify => Service["fail2ban"],
	}
}
