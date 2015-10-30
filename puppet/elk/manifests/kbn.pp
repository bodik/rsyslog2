# == Class: elk::kbn
#
# Class will ensure installation of:
# - kibana and apache virtualhost using example42's modules
# - set of static dashboards
# - general dasboard /dash.html
#
# === Parameters
#
# [*kibana_webserver*]
#   which webserver should be managed with examples42-kibana class
#   set to false to disable automatic webserver configuration
#
# [*proxyto*]
#   will create https proxy for connecting to local es instance. Parameter
#   can be either static or will be selected automatically as eth1 (gate) or eth0
#   (public/singlenode) ipaddress
#
# === Examples
#
#   class { "elk::kbn": }
#
class elk::kbn (
	$kibana_version = "3.1.0",
	$install_dir = "/opt/kibana",
	$proxyto = undef,
) {
	notice("INFO: pa.sh -v --noop --show_diff -e \"include ${name}\"")

	class { 'elk::kbn_install':
		kibana_version => $kibana_version,
		install_dir => $install_dir,
	}

	include metalib::apache2

	if ($proxyto) {
		$proxyto_real = $proxyto
	} else {
		if ($ipaddress_eth1) {
	                $proxyto_real = $ipaddress_eth1
	        } else {
	                $proxyto_real = $ipaddress_eth0
	        }
	}
        notice("will proxy to esd at $proxyto_real")
	metalib::apache2::a2enmod { "proxy": }
	metalib::apache2::a2enmod { "proxy_http": }
	file { "/etc/apache2/rsyslog2.cloud.d/01kibana.conf":
                content => template("${module_name}/etc/apache2/rsyslog2.cloud.d/01kibana.conf.erb"),
                owner => "root", group => "root", mode => "0644",
                require => [
			File["/etc/apache2/rsyslog2.cloud.d/"],
                        Metalib::Apache2::A2enmod["proxy", "proxy_http"],
			Exec["install_sslselfcert.sh"],
                        ],
                notify => Service["apache2"],
        }


	#kibana app config and customization
	file { "/opt/kibana/config.js":
		source => "puppet:///modules/${module_name}/opt/kibana/config.js",
		owner => "root", group => "root", mode => "0644",
		require => Class["elk::kbn_install"],
	}
	file { "/opt/kibana/app":
		ensure => directory, recurse => true, purge => false, 
		owner => "root", group => "root", mode => "0644",
		source => "puppet:///modules/${module_name}/opt/kibana/app",
		require => Class["elk::kbn_install"],
	}
}

