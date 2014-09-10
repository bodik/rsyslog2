
class rsyslog::install { 
	package { ["rsyslog", "rsyslog-gssapi", "rsyslog-relp"]:
		ensure => installed,
	}
}

