class warden3::hostcert (
	$hostname = "$fqdn",
	$dir = "/opt/hostcert",
) {

	file { "$dir":
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
		
        exec { "gen cert":
                command => "/bin/sh /puppet/warden3/bin/install_ssl_warden_ca_remote.sh ${dir}",
                creates => "${dir}/${fqdn}.crt",
		require => File["$dir"],
        }
}
