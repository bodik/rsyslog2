#!/usr/bin/puppet apply

class rsyslog::client (
	$version = "meta",
	$rsyslog_server_auto = true,
	$rsyslog_server_service = "_syselgss._tcp",
	$rsyslog_server = undef
) {
	class { "rsyslog::install": version => $version, }
	service { "rsyslog": ensure => running, }
	include metalib::avahi



	#tcp + relp - gssapi
	file { "/etc/rsyslog.conf":
		source => "puppet:///modules/rsyslog/etc/rsyslog-client.conf",
		owner => "root", group=> "root", mode=>"0644",
		require => Class["rsyslog::install"],
		notify => Service["rsyslog"],
		
	}




	if ( ($rsyslog_server_auto == true) ) {
		$rsyslog_server_real = avahi_findservice($rsyslog_server_service)
		notice("rsyslog_server_real discovered as ${rsyslog_server_real}")
	} elsif ($rediser_server) {
		$rsyslog_server_real = $rsyslog_server
	}

	if ( $rsyslog_server_real ) {
		if file_exists ("/etc/krb5.keytab") == 0 {
			$forward_template = "${module_name}/etc/rsyslog.d/meta-remote-omrelp.conf.erb"
		} else {
			$forward_template = "${module_name}/etc/rsyslog.d/meta-remote-omgssapi.conf.erb"
		}
		file { "/etc/rsyslog.d/meta-remote.conf":
			content => template($forward_template),
			owner => "root", group=> "root", mode=>"0644",
			require => Class["rsyslog::install"],
			notify => Service["rsyslog"],
		}
	}
}

