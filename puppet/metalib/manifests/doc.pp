# == Class: doc
#
# Class will ensure presence of all needed software for rendering rsyslog2 documentation
#
# === Examples
#
#  class { doc: }
#
# === Authors
#
# bodik@cesnet.cz
#
class metalib::doc {
	package { "ruby-dev":
		ensure => installed,
	}
	package { ['github-markdown','redcarpet']:
		ensure   => 'installed',
		provider => 'gem',
		require => Package["ruby-dev"],
	}
	package { "links":
		ensure => installed,
	}
}
