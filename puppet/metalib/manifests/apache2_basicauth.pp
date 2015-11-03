# == Class: metalib::apache2_basicauth
#
# Class will install basic auth with generated password for whole URI space.
# This class is just example, it's no meant to be very secure.
#
class metalib::apache2_basicauth() {
	include metalib::apache2
	
	file { "/etc/apache2/rsyslog2.cloud.d/basicauth.conf":
		source => "puppet:///modules/${module_name}/etc/apache2/rsyslog2.cloud.d/basicauth.conf",
		owner => "root", group => "root", mode => "0644",
		require => Package["apache2"],
		notify => Service["apache2"],
	}

	$basicauth_passfile = "/etc/apache2/rsyslog2.cloud.d/rsyslog2-htpasswd"
	$username = "rsyslog2"
	if ( file_exists($basicauth_passfile) == 0  ) {
		$basicauth_password_real = myexec("/bin/dd if=/dev/urandom bs=100 count=1 2>/dev/null | /usr/bin/sha256sum | /usr/bin/awk '{print \$1}'")
		notice("metalib::apache2_basicauth secret generated")
		exec { "generate htaccess file":
			command => "/usr/bin/htpasswd -bc ${basicauth_passfile} ${username} ${basicauth_password_real}",
			require => File["/etc/apache2/rsyslog2.cloud.d/basicauth.conf"],
			notify => Service["apache2"],
		}
		file { "${basicauth_passfile}.plaintext":
			content => "${username}:${basicauth_password_real}\n",
			owner => "root", group => "www-data", mode => "0640",
			require => File["/etc/apache2/rsyslog2.cloud.d/basicauth.conf"],
			notify => Service["apache2"],
		} 
	}
}
