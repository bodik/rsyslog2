# == Class: hpconpot
#
# w3-ized conpot
#
# === Examples
#
#  class { hpconpot: }
#
# === Authors
#
# bodik@cesnet.cz
#
class hpconpot (
	$install_dir = "/opt/conpot",

	$user = "conpot",

	$warden_server = undef,
	$warden_server_auto = true,
	$warden_server_service = "_warden-server._tcp",
) {

	if ($warden_server) {
                $warden_server_real = $warden_server
        } elsif ( $warden_server_auto == true ) {
                include metalib::avahi
                $warden_server_real = avahi_findservice($warden_server_service)
        }


	#conpot instal
	package { 
		["python", "python-pip", "libsmi2ldbl", "snmp-mibs-downloader", "python-dev", "libevent-dev", "libxslt1-dev", "libxml2-dev", "libmysqlclient-dev", "python-setuptools", "python-pkg-resources"]: 
		ensure => installed,
	}

	#perun mi ji krade
 	package { ["perun-slave", "perun-slave-meta"]: ensure => absent }	
	user { "${user}":
		ensure => present,
		require => Package["perun-slave", "perun-slave-meta"],
	}

	package { "conpot":
		ensure => latest,
		provider => "pip",
		require => Package["python-pip"],
	}
	
##	file { "${install_dir}":
##		ensure => directory,
##		group => "${user}", owner => "${user}", mode => "0644",
##		require => User["${user}"],
##	}
##	file { "${install_dir}/conpot.init":
##		content => template("${module_name}/glastopf.init"),
##		group => "root", owner => "root", mode => "0755",
##		require => File["/opt/glastopf"],
##	}
##	file { "/etc/init.d/glastopf":
##		ensure => link,
##		target => "${install_dir}/glastopf.init",
##		require => File["${install_dir}/glastopf.init"],
##	}
##
##
##	service { "glastopf":
##		ensure => running,
##		require => [File["${install_dir}/glastopf.cfg"], File["/etc/init.d/glastopf"], Exec["pip install glastopf"], Service["apache2"], Exec["python cap_net"]],
##	}
##
##
##
##
##	# warden_client pro kippo (basic w3 client, reporter stuff, run/persistence/daemon)
##	file { "${install_dir}/warden":
##		ensure => directory,
##		owner => "${user}", group => "${user}", mode => "0755",
##	}
##	file { "${install_dir}/warden/warden_client.py":
##		source => "puppet:///modules/${module_name}/warden_client/warden_client.py",
##		owner => "${user}", group => "${user}", mode => "0755",
##		require => File["${install_dir}/warden"],
##	}
##	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
##	file { "${install_dir}/warden/warden_client.cfg":
##		content => template("${module_name}/warden_client.cfg.erb"),
##		owner => "${user}", group => "${user}", mode => "0640",
##		require => File["${install_dir}/warden"],
##	}
##	class { "warden3::hostcert": 
##		warden_server => $warden_server_real,
##	}
##	exec { "register kippo sensor":
##		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n conpot -d ${install_dir}",
##		creates => "${install_dir}/registered-at-warden-server",
##		require => File["$install_dir"],
##	}
##
##	file { "${install_dir}/warden/conpot-reporter.py":
##		source => "puppet:///modules/${module_name}/reporter/conpot-reporter.py",
##		owner => "${user}", group => "${user}", mode => "0755",
##		require => File["${install_dir}/warden"],
##	}
##	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
##	file { "${install_dir}/warden/warden_client-conpot.cfg":
##		content => template("${module_name}/warden_client-conpot.cfg.erb"),
##		owner => "${user}", group => "${user}", mode => "0640",
##		require => File["${install_dir}/warden"],
##	}
##	file { "/etc/cron.d/warden-conpot":
##		content => template("${module_name}/warden-conpot.cron.erb"),
##		owner => "root", group => "root", mode => "0644",
##		require => User["${user}"],
##	}

	
}
