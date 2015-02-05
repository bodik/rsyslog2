class elkvut::networking() {
	case $hostname {
		'elkvut01': { $newaddr = '100.64.24.81' }
		'elkvut02': { $newaddr = '100.64.24.82' }
		'elkvut03': { $newaddr = '100.64.24.83' }
		'elkvut04': { $newaddr = '100.64.24.84' }
		'elkvut05': { $newaddr = '100.64.24.85' }
		'elkvut06': { $newaddr = '100.64.24.86' }
		'elkvut07': { $newaddr = '100.64.24.87' }
		'elkvut08': { $newaddr = '100.64.24.88' }
		'elkvut09': { $newaddr = '100.64.24.89' }
		'elkvut10': { $newaddr = '100.64.24.90' }
	}
	$newnetmask = '255.255.255.0'
	$newnetwork = '100.64.24.255'
	$newgateway = '100.64.24.1'

	file { "/etc/resolv.conf":
		content => "nameserver 147.229.2.10\nnameserver 147.229.3.100\n",
		owner => "root", group => "root", mode => "0644",
	}
	file { "/etc/network/interfaces":
		content => template("${module_name}/interfaces.erb"),
		owner => "root", group => "root", mode => "0644",
	}
}
