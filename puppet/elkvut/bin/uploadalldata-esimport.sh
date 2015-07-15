#!/bin/bash
#time bash elkvut/bin/uploadalldata-esimport.sh 1>/tmp/upload.log 2>&1

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

#user2709129
function jobmax
{
    typeset -i MAXJOBS=$1
    sleep .1
    while (( ($(pgrep -P $$ | wc -l) - 1) >= $MAXJOBS ))
    do
        sleep .1
    done
}

#################################################### main

sh /puppet/elkvut/bin/describe_cluster.sh

nproc=8
iter=0

t=$(timer)
echo "h2. == UPLOAD DATA BEGIN"
date
echo "uploading with esimport $nproc paralell processes"
#for all in $(find /data/data/ -type f | head -n1); do 
for all in $(find /data/data/ -type f); do
	echo "== uploading $all"
	time (sh /puppet/netflow/bin/dump.sh -v -f $all > /dev/shm/esimportupload.${iter}; python -m esimport -s $(facter ipaddress):39200 -f /dev/shm/esimportupload.${iter} -i logstash-nz -t nz; rm /dev/shm/esimportupload.${iter}) &
	iter=$(($iter+1))
    	jobmax $nproc
done
wait # Wait for the rest

date
printf 'Elapsed time: %s\n' $(timer $t)
echo "== UPLOAD DATA END"
