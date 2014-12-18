# == Class: mongomine::rsyslogweb
#
# Class will ensure installation of rsysloweb, python bottle aplication for
# mongodb collection browsing.  Also creates set of cronjobs which will compute
# crackers maps or fetch lists of tor nodes, ...
#
# === Parameters
#
# [*backend_email*] 
# [*alert_email*] 
#   send emited email messages to specific e-mail
#
# [*mta_package*]
# [*mta_fix_cloud_sender*] 
#   will tune postfix to rewrite sender addresses to something more 
#   non cloudish which will pass various filtering (nxdomain,...)
#
# === Examples
#
#   class { "mongomine::rsyslogweb": }
#


class mongomine::rsyslogweb (
	$backend_email = "bodik@cesnet.cz",
	$alert_email = "bodik@cesnet.cz",
	$mta_package = "postfix",
	$mta_fix_cloud_sender = true,
) {
	notice("INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include ${name}\"")

	package { ["apache2", "libapache2-mod-wsgi", "python-pip", "python-dateutil", "python-geoip"]:
		ensure => installed,
		notify => Service["apache2"],
	}
	service { "apache2": 
		ensure => running,
	}
	package { ["bottle", "pymongo"]:
		ensure => installed,
		provider => "pip",	
		notify => Service["apache2"],
	}
	file { "/opt/rsyslogweb":
		ensure => directory,
		source => "puppet:///modules/${module_name}/opt/rsyslogweb",
		recurse => "true",
		owner => "root", group => "root", mode => "0644",
		notify => Service["apache2"],
	}
	
	file  { "/etc/apache2/conf.d/rsyslogweb.conf":
		ensure => link,
		source => "puppet:///modules/${module_name}/opt/rsyslogweb/apache-proxy-bottle.conf",
		owner => "root", group => "root", mode => "0644",
		require => [Package["libapache2-mod-wsgi"], File["/opt/rsyslogweb"]],
		notify => Service["apache2"],
	}


	#this is a cloud dependency for mail alerting
	package { $mta_package: ensure => installed, }
	if ( $mta_package == "postfix" and $mta_fix_cloud_sender == true) {
		service { "postfix": }
		augeas { "postfix-rewrite-cloudsender":
		        context => "/files/etc/postfix/main.cf",
		        changes => [
		                "set smtp_generic_maps regexp:/etc/postfix/generic",
		        ],
		        require => Package["postfix"],
			notify => Service["postfix"],
		}
		file { "/etc/postfix/generic":
			content => "/root@vmes2.metacentrum.cz/ root@esb.metacentrum.cz\n",
			owner => "root", group => "root", mode => "0644",
			require => Package["postfix"],
			notify => Service["postfix"],
		}
	}

	cron { "maps3.py":
		command => "(cd /opt/rsyslogweb/; /usr/bin/python maps3.py 1>/dev/null)",
		environment => "MAILTO=${backend_email}",
		minute      => "*",
		require => [File["/opt/rsyslogweb"], Package["pymongo"]],
	}
	cron { "tor_fetchlists.py":
		command => "(cd /opt/rsyslogweb/; /usr/bin/python tor_fetchlists.py)",
		environment => "MAILTO=${backend_email}",
		minute      => "0",
		hour      => "*/4",
		require => [File["/opt/rsyslogweb"], Package["pymongo"]],
	}
	cron { "report_crackers.py":
		command => "(cd /opt/rsyslogweb/; /usr/bin/python report_crackers.py)",
		environment => "MAILTO=${alert_email}",
		minute      => "*/5",
		require => [File["/opt/rsyslogweb"], Package["pymongo"]],
	}




	package { ["libapache2-mod-php5", "php-pear", "php5-dev"]:
		ensure => installed,
		notify => Service["apache2"],
	}
	exec { ["pecl install mongo"]:
		command => "/usr/bin/pecl install mongo",
		unless => "/usr/bin/pecl list | grep mongo",
		require => [Package["php5-dev"], Package["php-pear"]],
		notify => Service["apache2"],
	}
	file { "/etc/php5/conf.d/mongo.ini":
		source => "puppet:///modules/${module_name}/etc/php5/conf.d/mongo.ini",
		owner => "root", group => "root", mode => "0644",
		require => [Package["libapache2-mod-php5"], Exec["pecl install mongo"]],
		notify => Service["apache2"],
	}
	file { "/opt/rock":
		ensure => directory,
		source => "puppet:///modules/${module_name}/opt/rock",
		recurse => "true",
		owner => "root", group => "root", mode => "0644",
	}
}

