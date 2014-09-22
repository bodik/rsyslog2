# == Class: metalib::doc
#
# Class for installingall software needed for rendering rsyslog2 documentation.
# Used manually.
#
# === Examples
#
# include metalib::doc
#
class metalib::doc {
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
}
