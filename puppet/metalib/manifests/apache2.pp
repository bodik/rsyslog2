#dependency placeholder, just simple cross sharing deps sux
class metalib::apache2 {
	package { "apache2": ensure => installed, }
	service { "apache2": }
}
