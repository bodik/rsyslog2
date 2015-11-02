# == Class: gate
#
# Example class giving raw overview how to create cloud gateway
#
class gate {
        include metalib::base
        include metalib::fail2ban
        include iptables

	class { "rediser": }
        # esc on secondary interface, eth1 should be discovered and prefered by kbn for /head proxy
        class { "elk::esc":
                network_host =>  $ipaddress_eth1,
        }
        class { "elk::kbn": }

        include metalib::apache2
        include mongomine::rsyslogwebproxy
}
