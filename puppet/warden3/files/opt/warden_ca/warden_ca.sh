#!/bin/sh

#http://spootnik.org/tech/2013/05/30_neat-trick-using-puppet-as-your-internal-ca.html
# init ca, list
#  puppet cert --confdir /opt/warden-ca list
# generate keys
#  puppet cert --confdir /opt/warden-ca generate ${admin}.users.priv.example.com
# revoke keys
#  puppet cert revoke

CADIR="/opt/warden_ca"
OPTS="--confdir $CADIR"

usage() {
	echo "$0 init"
	echo "$0 show_ca"
	echo "$0 get_ca_crt"
	echo "$0 list"
	echo "$0 get_crl"
	echo "$0 generate FQDN"
	echo "$0 sign FQDN"
	echo "$0 show_crt FQDN"
	echo "$0 get_crt FQDN"
	echo "$0 get_key FQDN"
	echo "$0 revoke FQDN"
}

case "$1" in
	list|init)
		puppet cert $OPTS list --all
	;;
	show_ca)
		puppet ca print ca $OPTS
	;;
	get_ca_crt)
		cat $CADIR/ssl/ca/ca_crt.pem
	;;
	get_crl)
		puppet certificate_revocation_list find dummy --terminus ca $OPTS
	;;
	generate)
		puppet cert $OPTS generate $2
	;;
	sign)
		puppet cert $OPTS sign $2
	;;
	get_crt)
		puppet certificate find $2 --ca-location local $OPTS
	;;
	get_key)
		#dunno why key find return such a ugly string
		puppet key find $2 $OPTS | sed 's/\\n/\n/g' | sed 's/"//g' | egrep -v "^$"
	;;
	show_crt)
		puppet cert $OPTS print $2
	;;
	revoke)
		puppet cert $OPTS revoke $2
	;;
	*)
		usage
	;;
esac
