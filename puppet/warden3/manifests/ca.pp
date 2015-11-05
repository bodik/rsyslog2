# == Class: warden3::ca
#
# Class will ensure installation of warden3 automated ca for testing.
# CA is build around simple puppet ca which provides list, sign, revoke. 
# Inspired by http://spootnik.org/tech/2013/05/30_neat-trick-using-puppet-as-your-internal-ca.html
# init ca, list
#  puppet cert --confdir /opt/warden-ca list
# generate keys
#  puppet cert --confdir /opt/warden-ca generate ${admin}.users.priv.example.com
# revoke keys
#  puppet cert revoke
#
# TODO: allow changing ca service port
#
# === Parameters
#
# [*ca_name*]
#   ca name
#
# [*autosign*]
#   handle signing requests automatically (testing)
#
class warden3::ca (
	$ca_name = "warden3ca",
	$autosign = true,
) {
	file { "/opt/warden_ca":
		ensure => directory,
		owner => "root", group => "root", mode => "0700",
	}
	file { "/opt/warden_ca/puppet.conf":
		content => template("${module_name}/ca-puppet.conf.erb"),
		owner => "root", group => "root", mode => "0600",
	}
	file { "/opt/warden_ca/warden_ca.sh":
		source => "puppet:///modules/${module_name}/opt/warden_ca/warden_ca.sh",
		owner => "root", group => "root", mode => "0700",
	}
	exec { "warden_ca.sh init":
		command => "/bin/sh /opt/warden_ca/warden_ca.sh init",
		creates => "/opt/warden_ca/ssl/ca/ca_crt.pem",
		require => File["/opt/warden_ca/puppet.conf", "/opt/warden_ca/warden_ca.sh"],
	}
	file { "/opt/warden_ca/warden_ca_http.py":
		source => "puppet:///modules/${module_name}/opt/warden_ca/warden_ca_http.py",
		owner => "root", group => "root", mode => "0700",
	}
	file { "/etc/init.d/warden_ca_http":
		source => "puppet:///modules/${module_name}/opt/warden_ca/warden_ca_http.init",
		owner => "root", group => "root", mode => "0700",
		require => File["/opt/warden_ca/warden_ca_http.py"],
		notify => Exec["systemd_reload"],
	}
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "warden_ca_http": 
		enable => true,
		ensure => running,
		provider => init,
		require => [File["/etc/init.d/warden_ca_http"], Exec["systemd_reload"]],
	}
	if ($autosign) {
		file { "/opt/warden_ca/AUTOSIGN":
			content => "AUTOSIGN ENABLED",
			owner => "root", group => "root", mode => "0600",
	 	}
	} else {
		file { "/opt/warden_ca/AUTOSIGN":	ensure => absent }
	}
}
