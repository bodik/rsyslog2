#!/usr/bin/puppet apply

import '/puppet/lib.pp'

package { ["nfs-common","rpcbind", "dbus"]: ensure => absent, }
package { ["joe","nano", "pico"]: ensure => absent, }
package { ["vim", "mc", "git", "puppet", "augeas-lenses", "nagios-plugins-basic", "screen", "psmisc"]: ensure => installed, }

package { "krb5-user":
        ensure => installed,
}
download { "/etc/krb5.conf":
                uri => "https://download.zcu.cz/public/config/krb5/krb5.conf",
                owner => "root", group => "root", mode => "0644",
                timeout => 900;
}

file { "/etc/apt/sources.list.d/wheezy.list":
        source => "/puppet/templates/etc/apt/sources.list.d/wheezy.list",
        owner => "root", group => "root", mode => "0644",
        notify => Exec["apt-get update"],
}

#cron { "apt":
#  command => "/usr/bin/aptitude update 1>/dev/null",
#  user    => root,
#  hour    => 0,
#  minute  => 0
#}
#cron { "check_apt":
#  command => "/usr/lib/nagios/plugins/check_apt | /bin/grep -v 'APT OK'",
#  user    => root,
#  hour    => 1,
#  minute  => 0
#}

case $hostname {
        default: { $tmp_file = "/puppet/templates/etc/hosts.erb" }
}
file { "/etc/hosts":
        content => template($tmp_file),
        owner => "root", group => "root", mode => "0644",
}

file { [ "/etc/puppet/modules/customfacts/", "/etc/puppet/modules/customfacts/lib/", "/etc/puppet/modules/customfacts/lib/facter/" ]:
	ensure => "directory",
}
file { "/etc/puppet/modules/customfacts/lib/facter/file_exists.rb":
	source => "/puppet/templates/etc/puppet/modules/customfacts/lib/facter/file_exists.rb",
	owner => "root", group => "root", mode => "0644",
	require => File["/etc/puppet/modules/customfacts/lib/facter/"],
}

