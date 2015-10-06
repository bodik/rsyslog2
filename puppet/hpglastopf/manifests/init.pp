# == Class: hpglastopf
#
# w3-ized glastopf
#
# === Examples
#
#  class { hpglastopf: }
#
# === Authors
#
# bodik@cesnet.cz
#
class hpglastopf (
	$install_dir = "/opt/glastopf",

	$glastopf_user = "glastopf",

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


	#glastopf instal
	package { 
		["python", "python-openssl", "python-gevent", "libevent-dev", "python-dev", "build-essential", "make",
		"python-argparse", "python-chardet", "python-requests", "python-sqlalchemy", "python-lxml",
		"python-beautifulsoup", "python-pip", "python-setuptools",
		"g++", "git", "php5", "php5-dev", "liblapack-dev", "gfortran",
		"libxml2-dev", "libxslt1-dev",
		"libmysqlclient-dev",
		]: 
		ensure => installed,
	}

	#package { "distribute":
	#	ensure => latest,
	#	provider => "pip",
	#	require => Package["python-pip"],
	#}
	#package { "greenlet":
	#	ensure => latest,
	#	provider => "pip",
	#	require => Package["python-pip"],
	#}
	#pip provider just stopper to work with
	#Could not evaluate: Could not get latest version: HTTP-Error: 503 Service Temporarily Unavailable
	exec { "pip install distribute":
		command => "/usr/bin/pip install --upgrade distribute",
		creates => "/usr/local/lib/python2.7/dist-packages/distribute-0.7.3-py2.7.egg-info/installed-files.txt"
	}
	exec { "pip install greenlet":
		command => "/usr/bin/pip install --upgrade greenlet",
		creates => "/usr/local/lib/python2.7/dist-packages/greenlet.so"
	}
	

	$api_version = "20100525"
	exec { "/puppet/glastopf/bin/make-bfr.sh":
		command => "/bin/sh /puppet/glastopf/bin/make-bfr.sh",
		creates => "/usr/lib/php5/${api_version}/bfr.so",
		require => Package["php5-dev"],
	}
	
	file { "/etc/php5/conf.d/bfr.ini":
		content => template("${module_name}/bfr.ini.erb"),
		owner => "root", group => "root", mode => "0644",
		require => [Package["php5"], Exec["/puppet/glastopf/bin/make-bfr.sh"]],
	}

	#err: Could not prefetch package provider 'pip':
	#package { "glastopf":
	#	ensure => installed,
	#	provider => "pip",
	#	require => [Package["python-pip"], File["/etc/php5/conf.d/bfr.ini"]],
	#}
	exec { "pip install glastopf":
                command => "/usr/bin/pip install glastopf",
                creates => "/usr/local/lib/python2.7/dist-packages/glastopf/glastopf.cfg.dist",
		require => [Package["python-pip"], File["/etc/php5/conf.d/bfr.ini"], Package["python-dev"]],
        }

	file { "/opt/glastopf/data":
		source => "puppet:///modules/${module_name}/data",
		recurse => true,
		owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0644",
		require => [File["${install_dir}"], Exec["pip install glastopf"]],
	}


	#perun mi ji krade
 	package { ["perun-slave", "perun-slave-meta"]: ensure => absent }	
	user { "${glastopf_user}":
		ensure => present,
		require => Package["perun-slave", "perun-slave-meta"],
	}
	file { "${install_dir}":
		ensure => directory,
		group => "${glastopf_user}", owner => "${glastopf_user}", mode => "0644",
		require => User["glastopf"],
	}
	file { "${install_dir}/glastopf.init":
		content => template("${module_name}/glastopf.init"),
		group => "root", owner => "root", mode => "0755",
		require => File["/opt/glastopf"],
	}
	file { "/etc/init.d/glastopf":
		ensure => link,
		target => "${install_dir}/glastopf.init",
		require => File["${install_dir}/glastopf.init"],
	}
	file { "${install_dir}/glastopf.cfg":
		content => template("${module_name}/glastopf.cfg"),
		group => "root", owner => "root", mode => "0644",
		require => File["${install_dir}"],
	}

	package { "libcap2-bin": ensure => installed }
	exec { "python cap_net":
		command => "/sbin/setcap 'cap_net_bind_service=+ep' /usr/bin/python2.7",
		unless => "/sbin/getcap /usr/bin/python2.7 | grep cap_net_bind_service",
		require => Package["python"],
	}

	service { "apache2":
		ensure => stopped,
		require => Exec["pip install glastopf"],
	}
	service { "glastopf":
		ensure => running,
		require => [File["${install_dir}/glastopf.cfg"], File["/etc/init.d/glastopf"], Exec["pip install glastopf"], Service["apache2"], Exec["python cap_net"]],
	}


	# warden_client pro kippo (basic w3 client, reporter stuff, run/persistence/daemon)
	file { "${install_dir}/warden":
		ensure => directory,
		owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0755",
	}
	file { "${install_dir}/warden/warden_client.py":
		source => "puppet:///modules/${module_name}/warden_client/warden_client.py",
		owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
	file { "${install_dir}/warden/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}
	class { "warden3::hostcert": 
		warden_server => $warden_server_real,
	}
	exec { "register kippo sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n glastopf -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["$install_dir"],
	}

	file { "${install_dir}/warden/glastopf-reporter.py":
		source => "puppet:///modules/${module_name}/reporter/glastopf-reporter.py",
		owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
	file { "${install_dir}/warden/warden_client-glastopf.cfg":
		content => template("${module_name}/warden_client-glastopf.cfg.erb"),
		owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}
	file { "/etc/cron.d/warden-glastopf":
		content => template("${module_name}/warden-glastopf.cron.erb"),
		owner => "root", group => "root", mode => "0644",
		require => User["$glastopf_user"],
	}

	
}
