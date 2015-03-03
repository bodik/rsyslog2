#!/bin/bash
#time bash elkvut/bin/searchallqueries.sh 1>/tmp/search.log 2>&1

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

sh /puppet/elkvut/bin/describe_cluster.sh

t=$(timer)
echo "h2. == SEARCH DATA BEGIN"
date
for all in basicquesties-query1.rb basicquesties-query2.rb basicquesties-query3.rb basicquesties-query4.rb basicquesties-query5a.rb basicquesties-query6a.rb; do
	echo "== searching $all"
	time ruby $all
done
date
printf 'Elapsed time: %s\n' $(timer $t)
echo "== SEARCH DATA END"
