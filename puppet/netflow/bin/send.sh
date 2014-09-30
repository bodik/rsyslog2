#!/bin/sh

DP=49559

while getopts "f:d:p:" o; do
	case "${o}" in
		f)
			FILE=${OPTARG}
		;;
		d)
			DIP=${OPTARG}
		;;
		p)
			DP=${OPTARG}
		;;
	esac
done

if [ -z $DIP ]; then
	DIP=$(/puppet/metalib/avahi.findservice.sh "_rediser._tcp")
fi

sh /puppet/netflow/bin/dump.sh -f $FILE | nc -q0 $DIP $DP
