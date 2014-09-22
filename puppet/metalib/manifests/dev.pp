# == Class: metalib::dev
#
# Class for installling set of development and debugging packages. Used
# manually when needed
#
# === Examples
#
# include metalib::dev
#
# === Authors
#
# bodik@cesnet.cz
#
class metalib::dev { 
	package { ["tcpdump", "strace", "puppet-lint", "colordiff", "augeas-tools", "ngrep", "iotop", "atop", "rake"]: 
		ensure => installed, 
	}

	#package { ["openjdk-7-jdk"]:
	#	ensure => installed,
	#}

}

