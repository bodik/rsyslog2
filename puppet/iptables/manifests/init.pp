# == Class: iptables
#
# Class will ensure installation of iptables and iptables-persistent
#
# === Parameters
#
# [*rules_v4*]
#   iptables config file
#
# [*rules_v6*]
#   ip6tables config file
#
# === Examples
#
#   class { "iptables": 
#      irules_v4 => "puppet:///modules/${module_name}/somefile",
#   }
#
class iptables (
	$rules_v4 = "puppet:///modules/${module_name}/nonexistent",
	$rules_v6 = "puppet:///modules/${module_name}/nonexistent",
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")


	package { ["iptables"]: ensure => installed }
	package { "iptables-persistent": ensure => absent,}

	file { "/etc/init.d/iptables":
		source => "puppet:///modules/${module_name}/etc/init.d/iptables",
		owner => "root", group => "root", mode => "0755",
	}
	file { "/etc/init.d/ip6tables":
		source => "puppet:///modules/${module_name}/etc/init.d/ip6tables",
		owner => "root", group => "root", mode => "0755",
	}

	file { ["/var/lib/iptables", "/var/lib/ip6tables"]:
		ensure => "directory",
		owner => "root", group => "root", mode => "0750",
	}

	file { "/var/lib/iptables/active":
		source => [ $rules_v4, "puppet:///modules/${module_name}/PRIVATEFILE_rules.v4.${fqdn}", "puppet:///modules/${module_name}/rules.v4.${fqdn}", "puppet:///modules/${module_name}/rules.v4" ],
		owner => "root", group => "root", mode => "0640",
		require => File["/var/lib/iptables"],
		notify => Service["iptables"],
	}
	file { "/var/lib/ip6tables/active":
		source => [ $rules_v6, "puppet:///modules/${module_name}/PRIVATEFILE_rules.v6.${fqdn}", "puppet:///modules/${module_name}/rules.v6.${fqdn}", "puppet:///modules/${module_name}/rules.v6" ],
		owner => "root", group => "root", mode => "0640",
		require => File["/var/lib/ip6tables"],
		notify => Service["ip6tables"],
	}

	file { "/var/lib/iptables/inactive":
		source => "puppet:///modules/${module_name}/rules.v4-inactive",
		owner => "root", group => "root", mode => "0640",
		require => File["/var/lib/iptables"],
		notify => Service["iptables"],
	}
	file { "/var/lib/ip6tables/inactive":
		source => "puppet:///modules/${module_name}/rules.v6-inactive",
		owner => "root", group => "root", mode => "0640",
		require => File["/var/lib/ip6tables"],
		notify => Service["ip6tables"],
	}
	
	service { "iptables": 
		enable => true, 
		require => [File["/etc/init.d/iptables"], File["/var/lib/iptables/active"]],
	}
	service { "ip6tables": 
		enable => true, 
		require => [File["/etc/init.d/ip6tables"], File["/var/lib/ip6tables/active"]],
	}

}
