#!/bin/sh

if [ -z $1 ]; then
	NAMES="^auto"
else
	NAMES=$1
fi

JENKINS_CLI="java -jar /puppet/jenkins/jenkins-cli.jar -s http://$(facter fqdn):8081/"
$JENKINS_CLI list-jobs > /tmp/run_job.tmp.$$ || exit 1
for all in $(grep $1 /tmp/run_job.tmp.$$); do
	$JENKINS_CLI build $all -s || exit 1
done
rm /tmp/run_job.tmp.$$
