# == Class: metalib::base
#
# Class for ensuring basic setting of managed machine such as: editors, git,
# puppet, hostname, krb5 client lib, sysctl
#
# === Examples
#
#  include metalib::base
#
class metalib::base {
	notice($name)

	# globals
	contain metalib::wget
	contain metalib::sysctl-hardnet
	contain metalib::fail2ban

	# generic debianization from next,next,next,... install
	package { ["nfs-common","rpcbind"]: ensure => absent, }
	package { ["joe","nano", "pico"]: ensure => absent, }
	package { ["vim", "mc", "git", "puppet", "augeas-lenses", "nagios-plugins-basic", "screen", "psmisc"]: ensure => installed, }
	
	file { "/usr/local/bin/pa.sh":
		ensure => link,
		target => "/puppet/metalib/bin/pa.sh",
	}

	package { "krb5-user": ensure => installed, }
	metalib::wget::download { "/etc/krb5.conf":
                uri => "https://download.zcu.cz/public/config/krb5/krb5.conf",
                owner => "root", group => "root", mode => "0644",
                timeout => 900;
	}
	
	case $hostname {
	        default: { $tmp_file = "${module_name}/etc/hosts.erb" }
	}
	file { "/etc/hosts":
	        content => template($tmp_file),
	        owner => "root", group => "root", mode => "0644",
	}

	service { "puppet":
		ensure => stopped,
		enable => false,
	}
	file { "/etc/puppet/hiera.yaml":
		ensure => file,
	}
}

