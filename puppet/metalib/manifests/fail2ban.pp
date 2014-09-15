class metalib::fail2ban () {
	package { "fail2ban":
		ensure => installed,
	}
	service { "fail2ban":
		ensure => running,
	}

	file { "/etc/fail2ban/fail2ban.local":
		source => "puppet:///modules/metalib/etc/fail2ban/fail2ban.local",
		owner => "root", group=>"root", mode=>"0644",
		require => Package["fail2ban"],
		notify => Service["fail2ban"],
	}
}
