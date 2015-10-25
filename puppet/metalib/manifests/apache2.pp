# == Class: metalib::apache2
#
# Dependency placeholder.
#
class metalib::apache2 {
	package { "apache2": ensure => installed, }
	service { "apache2": }
}
