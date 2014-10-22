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
	package { ["iptables", "iptables-persistent"]: ensure => installed }

	file { "/etc/iptables/rules.v4":
		source => [ $rules_v4, "puppet:///modules/${module_name}/PRIVATEFILE_rules.v4.${fqdn}", "puppet:///modules/${module_name}/rules.v4.${fqdn}", "puppet:///modules/${module_name}/rules.v4" ],
		owner => "root", group => "root", mode => "0644",
		require => Package["iptables-persistent"],
		notify => Service["iptables-persistent"],
	}

	file { "/etc/iptables/rules.v6":
		source => [ $rules_v6, "puppet:///modules/${module_name}/PRIVATEFILE_rules.v6.${fqdn}", "puppet:///modules/${module_name}/rules.v6.${fqdn}", "puppet:///modules/${module_name}/rules.v6" ],
		owner => "root", group => "root", mode => "0644",
		require => Package["iptables-persistent"],
		notify => Service["iptables-persistent"],
	}

	service { "iptables-persistent": 
		enable => true, 
		require => [File["/etc/iptables/rules.v4"], File["/etc/iptables/rules.v6"]],
	}

	#legacy layer
	file { "/etc/init.d/iptables": ensure => link, target => "/etc/init.d/iptables-persistent" }
	file { "/etc/init.d/ip6tables": ensure => link, target => "/etc/init.d/iptables-persistent" }

}
