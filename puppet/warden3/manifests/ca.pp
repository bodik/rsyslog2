#http://spootnik.org/tech/2013/05/30_neat-trick-using-puppet-as-your-internal-ca.html
# init ca, list
#  puppet cert --confdir /opt/warden-ca list
# generate keys
#  puppet cert --confdir /opt/warden-ca generate ${admin}.users.priv.example.com
# revoke keys
#  puppet cert revoke

class warden3::ca (
	$ca_dir = "/opt/warden_ca",
	$ca_name = "warden3ca",
) {
	file { "$ca_dir":
		ensure => directory,
		owner => "root", group => "root", mode => "0700",
	}
	file { "$ca_dir/puppet.conf":
		content => template("${module_name}/ca-puppet.conf.erb"),
		owner => "root", group => "root", mode => "0600",
	}
	file { "$ca_dir/warden_ca.sh":
		content => template("${module_name}/warden_ca.sh.erb"),
		owner => "root", group => "root", mode => "0700",
	}
}
