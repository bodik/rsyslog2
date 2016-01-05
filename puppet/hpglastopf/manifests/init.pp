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
		"python-chardet", "python-requests", "python-sqlalchemy", "python-lxml",
		"python-beautifulsoup", "python-pip", "python-setuptools", "python-greenlet",
		"g++", "git", "php5", "php5-dev", "liblapack-dev", "gfortran", "libxml2-dev", "libxslt1-dev", "libmysqlclient-dev",
		"rsyslog"
		]: 
		ensure => installed,
	}

	$api_version = "20131226"
	exec { "/puppet/hpglastopf/bin/make-bfr.sh":
		command => "/bin/sh /puppet/hpglastopf/bin/make-bfr.sh",
		creates => "/usr/lib/php5/${api_version}/bfr.so",
		require => Package["php5-dev"],
	}
	
	file { "/etc/php5/cli/conf.d/bfr.ini":
		content => template("${module_name}/bfr.ini.erb"),
		owner => "root", group => "root", mode => "0644",
		require => [Package["php5"], Exec["/puppet/hpglastopf/bin/make-bfr.sh"]],
	}

	exec { "pip install glastopf":
                command => "/usr/bin/pip install glastopf",
                creates => "/usr/local/lib/python2.7/dist-packages/glastopf/glastopf.cfg.dist",
		require => [Package["python-pip", "python-setuptools", "python-dev"], File["/etc/php5/cli/conf.d/bfr.ini"]],
        }

	file { "/usr/local/lib/python2.7/dist-packages/glastopf/modules/handlers/emulators/data":
		source => "puppet:///modules/${module_name}/data",
		recurse => true,
		purge => false,
		owner => "root", group => "root", mode => "0644",
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
	file { "${install_dir}/glastopf.cfg":
		content => template("${module_name}/glastopf.cfg"),
		group => "root", owner => "root", mode => "0644",
		require => File["${install_dir}"],
	}
	package { "libcap2-bin": ensure => installed }
	exec { "python cap_net":
		command => "/sbin/setcap 'cap_net_bind_service=+ep' /usr/bin/python2.7",
		unless => "/sbin/getcap /usr/bin/python2.7 | grep cap_net_bind_service",
		require => [Package["python"], Package["libcap2-bin"]]
	}
	file { "/etc/init.d/glastopf":
		ensure => link,
		target => "${install_dir}/glastopf.init",
		require => [File["${install_dir}/glastopf.init"], File["${install_dir}/glastopf.cfg"], Exec["pip install glastopf"], Exec["python cap_net"]],
		notify => [Service["glastopf"], Exec["systemd_reload"]],
	}
	exec { "systemd_reload":
		command     => '/bin/systemctl daemon-reload',
		refreshonly => true,
	}
	service { "apache2":
		ensure => stopped,
		enable => false,
		require => Exec["pip install glastopf"],
	}
	service { "glastopf":
		ensure => running,
		enable => true,
		require => [File["/etc/init.d/glastopf"], Exec["systemd_reload"]],
	}


	# warden_client pro kippo (basic w3 client, reporter stuff, run/persistence/daemon)
	file { "${install_dir}/warden":
		ensure => directory,
		owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0755",
	}
	file { "${install_dir}/warden/warden_client.py":
		source => "puppet:///modules/${module_name}/sender/warden_client.py",
		owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$w3c_name = "cz.cesnet.flab.${hostname}"
	file { "${install_dir}/warden/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}

	#reporter

        file { "${install_dir}/warden/warden_utils_flab.py":
                source => "puppet:///modules/${module_name}/sender/warden_utils_flab.py",
                owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0755",
        }
	file { "${install_dir}/warden/warden_sender_glastopf.py":
		source => "puppet:///modules/${module_name}/sender/warden_sender_glastopf.py",
		owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0755",
		require => File["${install_dir}/warden"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
	file { "${install_dir}/warden/warden_client_glastopf.cfg":
		content => template("${module_name}/warden_client_glastopf.cfg.erb"),
		owner => "${glastopf_user}", group => "${glastopf_user}", mode => "0640",
		require => File["${install_dir}/warden"],
	}
	file { "/etc/cron.d/warden_glastopf":
		content => template("${module_name}/warden_glastopf.cron.erb"),
		owner => "root", group => "root", mode => "0644",
		require => User["$glastopf_user"],
	}

	
	warden3::hostcert { "hostcert":
		warden_server => $warden_server_real,
	}
	exec { "register glastopf sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n ${w3c_name}.glastopf -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["$install_dir"],
	}
}
