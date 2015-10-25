# == Class: metalib::dev
#
# Class for installling set of development, debugging and packages needed
# for documentation generation. Used manually when needed.
#
# === Examples
#
#  include metalib::dev
#
class metalib::dev { 
	package { ["tcpdump", "strace", "puppet-lint", "colordiff", "augeas-tools", "ngrep", "iotop", "atop", "rake"]: 
		ensure => installed, 
	}

	package { "ruby-dev":
		ensure => installed,
	}
	package { ['redcarpet' ,'rdoc', 'github-markup']:
		ensure   => 'installed',
		provider => 'gem',
		require => Package["ruby-dev"],
	}
	package { "links":
		ensure => installed,
	}

	#package { ["openjdk-7-jdk"]:
	#	ensure => installed,
	#}

}

