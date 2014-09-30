# == Class: rsyslog::client
#
# Class will ensure installation of rsyslog packages and configures daemon to client mode eg. : 
# - forwards all logs to rsyslog server using omrelp or omgssapi on krb5 enabled nodes
#
# === Parameters
#
# [*version*] specific version to install (see rsyslog::install) 
#
# [*rsyslog_server*] hostname or ip to forward all logs to (default undef)
#
# [*rsyslog_auto*] perform rsyslog server autodiscovery by avahi (defult true)
#
# [*rsyslog_service*] name of rsyslog server service to discover (default "_syselgss._tcp")
#
# === Examples
#
# install default version, perform autodiscovery and forward logs to rsyslog server
#
#   include rsyslog::client
#
# install rsyslog from jessie, forwardm logs to designated server node
#
#   class { "rsyslog::client": 
#     version => "jessie", 
#     rsyslog_server => "1.2.3.4", 
#   }
#
# install rsyslog client and do not forward gathered log anywhere
#
#   class { "rsyslog::server": 
#     rsyslog_auto => false, 
#   }
#
class rsyslog::client (
	$version = "meta",
	$rsyslog_server = undef,
	$rsyslog_server_auto = true,
	$rsyslog_server_service = "_syselgss._tcp",
) {
	class { "rsyslog::install": version => $version, }
	service { "rsyslog": ensure => running, }



	#tcp + relp - gssapi
	file { "/etc/rsyslog.conf":
		source => "puppet:///modules/rsyslog/etc/rsyslog-client.conf",
		owner => "root", group=> "root", mode=>"0644",
		require => Class["rsyslog::install"],
		notify => Service["rsyslog"],
		
	}




	if ( $rediser_server ) {
		$rsyslog_server_real = $rsyslog_server
	} elsif ( $rsyslog_server_auto == true ) {
		include metalib::avahi
		$rsyslog_server_real = avahi_findservice($rsyslog_server_service)
		notice("rsyslog_server_real discovered as ${rsyslog_server_real}")
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
	        notice("forward ACTIVE")
	} else {
		file { "/etc/rsyslog.d/meta-remote.conf":
			ensure => absent,
		}
	        notice("forward PASSIVE")
	}
}

