#!/bin/sh

/puppet/jenkins/metacloud.init login
VMLIST=$(/puppet/jenkins/metacloud.init list | grep "R[SC]-" |awk '{print $4}')

for all in $VMLIST; do
	VMNAME=$all /puppet/jenkins/metacloud.init ssh "(sh /rsyslog2/test02/local_logclean.sh </dev/null 1>/dev/null 2>/dev/null)"
done

