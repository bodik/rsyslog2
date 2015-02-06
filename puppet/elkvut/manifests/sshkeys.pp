class elkvut::sshkeys {
	file { "/root/.ssh":
		ensure => directory,
		owner => "root", group => "root", mode => "0700",
	}
	file { "/root/.ssh/authorized_keys":
		content => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhRDjXcoOtJajKt41sxKKqT1fJ+I/lJnQ2jZjf/r7pxrYuOXi4kXXhQf6ZXN+oqIvAUWDyY5tvkVgQ6P4rFJff3lGDUmAujOrrI6t/DesWlx7kF3X/Vw7I1sy9zrndFd+jdcPIYESkDmAtRQMFE5iFlmplBfQvqLzOHEaPiCnk8lLfYEvQm+chhhPjSqgzphFNowFeSUYCHDMzad9tWu4rFe3IQIsHf/lhLbjMicZ4OmI5XncFKROthhovsuAWINDXUA7RbbvQA681vJKHyCHfo9TcVckOC7czVCpvNFQWALqAVXN9XnpG7PfJwLQJrgtemWhAbol7nbPNpC9czl/J elkvut\n",
		owner => "root", group => "root", mode => "0644",
	}

}
