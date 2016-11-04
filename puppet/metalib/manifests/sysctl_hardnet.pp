# == Class: metalib::sysctl_hardnet
#
# Hardens networking on linux box. Used internally.
#
class metalib::sysctl_hardnet {
	file { "/etc/sysctl.d/hardnet.conf":
		source => "puppet:///modules/${module_name}/etc/sysctl.d/hardnet.conf",
		owner => "root", group => "root", mode => "0644",
	}
	exec { "force setting":
		command => "/sbin/sysctl --load=/etc/sysctl.d/hardnet.conf",
		unless => "/sbin/sysctl -a | /bin/grep 'net.ipv6.conf.all.accept_ra = 0'",
		require => File["/etc/sysctl.d/hardnet.conf"],
	}
}
