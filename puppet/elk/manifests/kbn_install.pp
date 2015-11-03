class elk::kbn_install (
	$install_dir = "/opt/kibana",
	$kibana_version = "3.1.0",
	$work_dir = "/tmp/kibana-install-tempdir/"
) {

	contain metalib::wget
	metalib::wget::download { "/var/tmp/kibana-${kibana_version}.zip":
		uri => "http://download.elasticsearch.org/kibana/kibana/kibana-${kibana_version}.zip",
	        owner => "root", group => "root", mode => "0644",
                timeout => 900,
	}
	file { "$install_dir":
		ensure => directory,
	        owner => "root", group => "root", mode => "0644",
	}
	package { "zip": ensure => installed, }
	exec { "unzip kibana":
		command => "/usr/bin/unzip /var/tmp/kibana-${kibana_version}.zip -d /tmp/kibana-install-tempdir; cp -ar ${work_dir}/kibana-${kibana_version}/* ${install_dir}; rm -r ${work_dir}",
		creates => "${install_dir}/LICENSE.md",
		require => [Metalib::Wget::Download["/var/tmp/kibana-${kibana_version}.zip"], Package["zip"], File["$install_dir"]],
	}

}
