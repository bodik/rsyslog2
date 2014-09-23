# == Class: rsyslog::server
#
# Class will ensure installation of rsyslog packages and configures daemon to server mode eg. :
# - imtcp, imrelp, optionally imgssapi on krb5 enabled nodes
# - stores all incoming logs into IP based directory stucture
# - optionaly forwards all gathered logs to rediser for analytics (omfwd).
# - announce self to others using avahi.
#
# === Parameters
#
# [*version*]
#   specific version to install (see rsyslog::install) 
#
# [*rediser_server*]
#   hostname or ip to forward all logs to for analytics, has precedence over rediser_auto
#   (default undef)
#
# [*rediser_auto*]
#   perform rediser autodiscovery by avahi (defult true)
#
# [*rediser_service*]
#   name of rediser service to discover (default "_rediser._tcp")
#
# === Examples
#
# install default version, perform autodiscovery and forward logs to rdiser
#
#   include rsyslog::server
#
# install rsyslog from jessie, forwardm logs to designated analytics node
#
#   class { "rsyslog::server": 
#      version => "jessie",
#      rediser_server => "1.2.3.4",
#   }
#
# install rsyslog server and do not forward gathered log anywhere
#
#   class { "rsyslog::server":
#     rediser_auto => false,
#   }
#
class rsyslog::server ( 
	$version = "meta",
	$rediser_server = undef,
	$rediser_auto = true,
	$rediser_service = "_rediser._tcp",
) {

	class { "rsyslog::install": version => $version, }
	service { "rsyslog": ensure => running, }



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



	if ($rediser_server) {
		$rediser_server_real = $rediser_server
	} elsif ( $rediser_auto == true ) {
		$rediser_server_real = avahi_findservice($rediser_service)
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
	include metalib::avahi
	file { "/etc/avahi/services/sysel.service":
		source => "puppet:///modules/${module_name}/etc/avahi/sysel.service",
		owner => "root", group => "root", mode => "0644",
		require => Package["avahi-daemon"], #tady ma byt class ale tvori kruhovou zavislost
		notify => Service["avahi-daemon"],
	}
}
