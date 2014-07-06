#!/bin/sh

/puppet/jenkins/metacloud.init login
VMLIST=$(/puppet/jenkins/metacloud.init list | grep "R[SC]-" |awk '{print $4}')

for all in $VMLIST; do
	VMNAME=$all /puppet/jenkins/metacloud.init ssh "pgrep -f testi.sh | xargs kill"
done

