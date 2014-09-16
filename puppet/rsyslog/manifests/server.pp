#!/usr/bin/puppet apply

class rsyslog::server ( 
	$version = "meta",
	$rediser_auto = true,
	$rediser_service = "_rediser._tcp",
	$rediser_server = undef,
) {

	class { "rsyslog::install": version => $version, }
	service { "rsyslog": ensure => running, }
	include metalib::avahi



	file { "/etc/rsyslog.d.cloud":
		ensure => directory,
	}
	#tcp + relp + gssapi
	file { "/etc/rsyslog.conf":
		source => "puppet:///modules/${module_name}/etc/rsyslog-server.conf",
		owner => "root", group=> "root", mode=>"0644",
		require => [Class["rsyslog::install"], File["/etc/rsyslog.d.cloud"]],
		notify => Service["rsyslog"],
	}



	#TODO: toto neni hezke ale vyrovnava to rozdil mezi metacloudem a magratheou ve smyslu provisioningu keytabu
	if file_exists ("/etc/krb5.keytab") == 1 {
		file { "/etc/rsyslog.d.cloud/00-imgssapi.conf":
			content => template("${module_name}/etc/rsyslog.d.cloud/00-imgssapi.conf"),
			owner => "root", group=> "root", mode=>"0644",
			require => [File["/etc/rsyslog.d.cloud"], Class["rsyslog::install"]],
			notify => Service["rsyslog"],
		}
	        notice("imgssapi ACTIVE")
	} else {
		notice("imgssapi PASSIVE")
	}



	if ( ($rediser_auto == true) ) {
		$rediser_server_real = avahi_findservice($rediser_service)
	} elsif ($rediser_server) {
		$rediser_server_real = $rediser_server
	}

	if ( $rediser_server_real ) {
		file { "/etc/rsyslog.d.cloud/20-forwarder-rediser-syslog.conf":
			content => template("${module_name}/etc/rsyslog.d.cloud/20-forwarder-rediser-syslog.conf.erb"),
			owner => "root", group=> "root", mode=>"0644",
			require => [File["/etc/rsyslog.d.cloud"], Class["rsyslog::install"]],
			notify => Service["rsyslog"],
		}
	        notice("forward rediser ACTIVE")
	} else {
		notice("forward rediser PASSIVE")
	}



	#kvuli testovani
	#tcpkill
	package { ["libpcap0.8", "libnet1"]:
		ensure => installed,
	}

	#autoconfig
	file { "/etc/avahi/services/sysel.service":
		source => "puppet:///modules/${module_name}/etc/avahi/sysel.service",
		owner => "root", group => "root", mode => "0644",
		require => Package["avahi-daemon"], #tady ma byt class ale tvori kruhovou zavislost
		notify => Service["avahi-daemon"],
	}
}
