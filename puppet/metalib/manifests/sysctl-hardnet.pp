class metalib::sysctl-hardnet {
	notice($name)
	notice("INFO: puppet apply -v --noop --show_diff --modulepath=/puppet -e \"include ${name}\"")

	file { "/etc/sysctl.d/hardnet.conf":
		source => "puppet:///modules/${module_name}/etc/sysctl.d/hardnet.conf",
		owner => "root", group => "root", mode => "0644",
	}
}
