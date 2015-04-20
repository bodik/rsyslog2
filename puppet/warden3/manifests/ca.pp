#http://spootnik.org/tech/2013/05/30_neat-trick-using-puppet-as-your-internal-ca.html
# init ca, list
#  puppet cert --confdir /opt/warden-ca list
# generate keys
#  puppet cert --confdir /opt/warden-ca generate ${admin}.users.priv.example.com
# revoke keys
#  puppet cert revoke

class warden3::ca (
	$ca_name = "warden3ca",
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
	file { "/opt/warden_ca/warden_ca_http.py":
		source => "puppet:///modules/${module_name}/opt/warden_ca/warden_ca_http.py",
		owner => "root", group => "root", mode => "0700",
	}
	file { "/etc/init.d/warden_ca_http":
		source => "puppet:///modules/${module_name}/opt/warden_ca/warden_ca_http.init",
		owner => "root", group => "root", mode => "0700",
	}
	service { "warden_ca_http": 
		enable => true,
		ensure => running,
		require => File["/etc/init.d/warden_ca_http"],
	}

}
