# metalib

A set of support classes and helpers used within rsyslog2 puppet ecosystem.


## avahi.findservice.sh

Discover service by name using Avahi mDNS. Prints resolved hostname or IPv4 address.
Ensures installation of avahi-daemon on execution to aid lib/facter/avahi_findservice.rb
at bootstrap time.

### Examples
	$> avahi.findservice.sh _service1._tcp
	hostnamex.domain.tld
	$> avahi.findservice.sh _notpresent._tcp
	$>


## lib.sh

Set of shell subroutines used within rsyslog2 puppet ecosystem.

