# == Class: gate
#
# Example class giving raw overview how to create cloud gateway
#
class gate {
        include metalib::base
        include metalib::fail2ban
        include iptables


        # with rediser
        include rediser
        # esc on secondary interface
        class { "elk::esc":
                network_host =>  $ipaddress_eth1,
        }
        class { "elk::kbn":
                kibana_webserver => false,
                kibana_elasticsearch_url => 'https://"+window.location.hostname+"/head'
        }


        #package apache2
        ##package { "apache2": ensure => installed, }
        # proxy config pass esc
        include metalib::apache2
        include mongomine::rsyslogwebproxy

}
