#!/bin/sh

/puppet/jenkins/bin/metacloud.init login
VMLIST=$(/puppet/jenkins/bin/metacloud.init list | grep "R[SC]-" |awk '{print $4}')

for all in $VMLIST; do
	VMNAME=$all /puppet/jenkins/bin/metacloud.init ssh "pgrep -f testi.sh | xargs kill"
done

