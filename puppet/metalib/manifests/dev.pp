class metalib::dev {
	package { ["tcpdump", "strace", "puppet-lint", "colordiff", "augeas-tools", "ngrep", "iotop", "atop"]: ensure => installed, }

	package { ["openjdk-7-jdk"]:
	        ensure => installed,
	}
}
 
