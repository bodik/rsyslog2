#!/usr/bin/puppet apply

import '/puppet/rsyslog.pp'
class { "rsyslog": }

#toto neni hezke ale co se da delat
import '/puppet/avahi.pp'

class rsyslog-client (
	$rsyslog_server = "sysel.metacentrum.cz"
) {

	#tcp + relp - gssapi
	file { "/etc/rsyslog.conf":
		source => "/puppet/templates/etc/rsyslog-client.conf",
		owner => "root", group=> "root", mode=>"0644",
		require => Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"],
		notify => Service["rsyslog"],
		
	}

	if file_exists ("/etc/krb5.keytab") == 0 {
		$forward_template = "/puppet/templates/etc/rsyslog.d/meta-remote-omrelp.conf.erb"
	} else {
		$forward_template = "/puppet/templates/etc/rsyslog.d/meta-remote-omgssapi.conf.erb"
	}
	file { "/etc/rsyslog.d/meta-remote.conf":
		#content => template("/puppet/templates/etc/rsyslog.d/meta-remote-omfwd.conf.erb"),
		content => template($forward_template),
		owner => "root", group=> "root", mode=>"0644",
		require => [Package["rsyslog", "rsyslog-gssapi", "rsyslog-relp"], Service["avahi-daemon"]],
		notify => Service["rsyslog"],
	}
}

if ( $rsyslog_server ) {
	class { "rsyslog-client":
		#toto by melo prijit z facteru
		rsyslog_server => $rsyslog_server,
	}
} else {
	warning("SKIPPED rsyslog-client, facts missing")
}
