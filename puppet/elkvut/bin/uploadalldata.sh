#!/bin/bash

###################################################### funcs
# Elapsed time.  Usage:
#   t=$(timer)
#   ... # do something
#   printf 'Elapsed time: %s\n' $(timer $t)
#      ===> Elapsed time: 0:01:12
#####################################################################
# If called with no arguments a new timer is returned.
# If called with arguments the first is used as a timer
# value and the elapsed time is returned in the form HH:MM:SS.
function timer()
{
    if [[ $# -eq 0 ]]; then
        echo $(date '+%s')
    else
        local  stime=$1
        etime=$(date '+%s')

        if [[ -z "$stime" ]]; then stime=$etime; fi

        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%d:%02d:%02d' $dh $dm $ds
    fi
}


#################################################### main

echo "cluster tools update begin"
sh /puppet/elkvut/bin/forall.sh 'sh /puppet/bootstrap.install.sh 1>/dev/null'
echo "cluster tools update end"

echo "h2. == DESCRIPTION BEGIN"
echo "CLUSTER DESCRIPTION"

echo "h3. === describe.rb begin"
sh /puppet/elkvut/bin/forall.sh 'ruby /puppet/elkvut/bin/describe.rb'
echo "== describe.rb end"

echo "h3. === _nodes/_all begin"
curl -XGET "http://$(facter ipaddress):39200/_nodes/_all/os,process,jvm,network,transport,http?pretty=true"
echo "=== _nodes/_all end"

echo "h3. === show_nodes.sh begin"
sh /puppet/elkvut/bin/show_nodes.sh
echo "=== show_nodes.sh end"

echo "h3. === data to send begin"
find /data/data/ -type f -ls
echo "files count:"
find /data/data/ -type f -ls | wc
echo "files size:"
du -sh /data/data/
echo "=== data to send end"

echo "== DESCRIPTION END"


t=$(timer)
echo "h2. == UPLOAD DATA BEGIN"
date
for all in $(find /data/data/ -type f | head -n1); do 
#for all in $(find /data/data/ -type f); do
	echo "== uploading $all"
	time sh netflow/bin/send.sh -f $all
done
date
printf 'Elapsed time: %s\n' $(timer $t)
echo "== UPLOAD DATA END"
