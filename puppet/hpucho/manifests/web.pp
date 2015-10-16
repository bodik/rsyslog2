#!/usr/bin/puppet apply

class hpucho::web (
	$install_dir = "/opt/uchoweb",
	
	$port = 8080,
	$personality = "Apache Tomcat/7.0.56 (Debian)",
	$content = "content-tomcat.tgz",
	
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

	# application
	package { "python-flask": #uchoweb1
		ensure => installed, 
	}
	package { "python-jinja2": #uchoweb2
		ensure => installed, 
	}
	file { ["${install_dir}"]:
		ensure => directory,
		owner => "root", group => "root", mode => "0755",
	}
	file { "${install_dir}/uchoweb.py":
		source => "puppet:///modules/${module_name}/uchoweb/uchoweb2.py",
		owner => "root", group => "root", mode => "0755",
		require => [File["${install_dir}"], Package["python-flask"]],
		notify => Service["uchoweb"],
	}
	file { "${install_dir}/content.tgz":
		source => "puppet:///modules/${module_name}/uchoweb/${content}",
		owner => "root", group => "root", mode => "0644",
		require => File["${install_dir}"],
	}
	exec { "content":
		command => "/bin/tar xzf content.tgz",
		cwd => "${install_dir}",
		creates => "${install_dir}/content",
		require => File["${install_dir}/content.tgz"],
	}
	file { "/etc/init.d/uchoweb":
		content => template("${module_name}/uchoweb.init.erb"),
		owner => "root", group => "root", mode => "0755",
		require => [File["${install_dir}/uchoweb.py", "${install_dir}/warden_client-uchoweb.cfg"], Exec["content"]],
	}
	service { "uchoweb": 
		enable => true,
		ensure => running,
		provider  => "init",
		require => File["/etc/init.d/uchoweb"],
	}


	#autotest
	package { ["netcat"]: ensure => installed, }




	# warden_client
	file { "${install_dir}/warden_client.py":
		source => "puppet:///modules/${module_name}/warden_client.py",
		owner => "root", group => "root", mode => "0755",
		require => File["${install_dir}"],
	}
	$fqdn_rev = myexec("echo ${fqdn} | awk '{n=split(\$0,A,\".\");S=A[n];{for(i=n-1;i>0;i--)S=S\".\"A[i]}}END{print S}'")
	file { "${install_dir}/warden_client.cfg":
		content => template("${module_name}/warden_client.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
	}
	$anonymised_target_net = myexec("/usr/bin/facter ipaddress | sed 's/\\.[0-9]*\\.[0-9]*\\.[0-9]*$/.0.0.0/'")
	file { "${install_dir}/warden_client-uchoweb.cfg":
		content => template("${module_name}/warden_client-uchoweb.cfg.erb"),
		owner => "root", group => "root", mode => "0640",
		require => File["${install_dir}"],
		notify => Service["uchoweb"],
	}
	class { "warden3::hostcert": 
		warden_server => $warden_server_real,
	}
	exec { "register uchoweb sensor":
		command	=> "/bin/sh /puppet/warden3/bin/register_sensor.sh -s ${warden_server_real} -n uchoweb -d ${install_dir}",
		creates => "${install_dir}/registered-at-warden-server",
		require => File["${install_dir}"],
	}

}
