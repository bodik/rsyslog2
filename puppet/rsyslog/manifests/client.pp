#!/usr/bin/puppet apply

class rsyslog::client (
	$version = "meta",
	$rsyslog_server = "sysel.metacentrum.cz"
) {
	class { "rsyslog::install": 
		version => $version,
	}
        service { "rsyslog":
                ensure => running,
        }

	#tcp + relp - gssapi
	file { "/etc/rsyslog.conf":
		source => "puppet:///modules/rsyslog/etc/rsyslog-client.conf",
		owner => "root", group=> "root", mode=>"0644",
		require => Class["rsyslog::install"],
		notify => Service["rsyslog"],
		
	}

	if file_exists ("/etc/krb5.keytab") == 0 {
		$forward_template = "/puppet/templates/etc/rsyslog.d/meta-remote-omrelp.conf.erb"
		#content => template("/puppet/templates/etc/rsyslog.d/meta-remote-omfwd.conf.erb"),
	} else {
		$forward_template = "/puppet/templates/etc/rsyslog.d/meta-remote-omgssapi.conf.erb"
	}
	file { "/etc/rsyslog.d/meta-remote.conf":
		content => template($forward_template),
		owner => "root", group=> "root", mode=>"0644",
		require => [Class["rsyslog::install"], Class["avahi"]],
		notify => Service["rsyslog"],
	}
}

