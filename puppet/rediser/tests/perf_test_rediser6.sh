#!/bin/sh

set -e
. /puppet/metalib/bin/lib.sh

TESTID="ti$(date +%s)"
LEN=11
VERSIONTOTEST="new"

usage() { echo "Usage: $0 [-c <TESTLEN>] [-n new|old]" 1>&2; exit 1; }
while getopts "c:n:" o; do
    case "${o}" in
        c)
            LEN=${OPTARG}
            ;;
        n)
            VERSIONTOTEST=${OPTARG}
            ;;
        *)
            usage
        ;;
    esac
done
shift $((OPTIND-1))



LOG="/tmp/perf_test_rediser6.sh.log.$$"
handler()
{
    kill -9 $PID_REDISER $PID_READER
}
trap handler INT



echo "INFO: test precheck"
/usr/lib/nagios/plugins/check_procs --argument-array="ruby tests/perf_redis_reader.rb" -c 0:0
if [ $? -ne 0 ]; then
	rreturn 1 "$0 perf_redis_reader.rb check_procs already running"
fi
/usr/lib/nagios/plugins/check_procs --argument-array="ruby tests/perf_rediser_writer.rb" -c 0:0
if [ $? -ne 0 ]; then
	rreturn 1 "$0 perf_rediser_writer.rb check_procs already running"
fi
/usr/lib/nagios/plugins/check_procs --argument-array="/puppet/rediser/bin/rediser-r6test-filter.sh" -c 0:0
if [ $? -ne 0 ]; then
	rreturn 1 "$0 /puppet/rediser/bin/rediser-r6test-filter.sh check_procs already running"
fi
/usr/lib/nagios/plugins/check_procs --argument-array="redis-key r6test" -c 0:0
if [ $? -ne 0 ]; then
	rreturn 1 "$0 rediser6 redis-key r6test check_procs already running"
fi



echo "INFO: test start"
TIME_START=$(date +%s)

#start rediser
#new
if [ $VERSIONTOTEST = "new" ]; then
	ruby bin/rediser6.rb --rediser-port 1234 --redis-host 127.0.0.1 --redis-port 16379 --redis-key r6test --flush-size 1000 --flush-timeout 10 --max-enqueue 500000 &
	PID_REDISER=$!
fi
#old
if [ $VERSIONTOTEST = "old" ]; then
	sh bin/rediser-r6test.init start
fi

sleep 3

#run reader
ruby tests/perf_redis_reader.rb > $LOG &
PID_READER=$!
# run writer
for i in $(seq 1 3); do
	ruby tests/perf_rediser_writer.rb -c $LEN -i $TESTID &
done
ruby tests/perf_rediser_writer.rb -c $LEN -i $TESTID
sleep 10


#disrupt ? ;)
#disrupt ? ;)


#stop rediser/teardown
#new
if [ $VERSIONTOTEST = "new" ]; then
	kill -TERM $PID_REDISER
fi
#old
if [ $VERSIONTOTEST = "old" ]; then
	sh bin/rediser-r6test.init stop
fi
count 30 #rediser4 has hardcoded teardown




TIME_STOP=$(date +%s)
#stop reader and get results
kill -TERM $PID_READER
sleep 1
#compute results
CLIENT="local"
TESTID="testid"
DELIVERED=$(cat $LOG | grep "INFO perf_redis_reader.rb: RESULT: read" | rev | awk '{print $1}' | rev)
DELIVEREDUNIQ=$DELIVERED
awk -F':' -v LEN=$(( $LEN * 4 )) -v DELIVEREDUNIQ=$DELIVEREDUNIQ -v DELIVERED=$DELIVERED -v CLIENT=$CLIENT -v TESTID=$TESTID -v TESTTIME=$(($TIME_STOP-$TIME_START)) '
BEGIN {
	PERC=DELIVERED/(LEN/100);
	PERCUNIQ=DELIVEREDUNIQ/(LEN/100);
	if(PERCUNIQ >= 99.9 && PERCUNIQ <= 100 )
		RES="OK";
	else
		RES="FAILED";
	print "RESULT TEST REDISER6:",RES,TESTID,CLIENT,"len",LEN,"deliv",DELIVERED,"rate",PERC"%","delivuniq",DELIVEREDUNIQ,"rateuniq",PERCUNIQ"%","testtime",TESTTIME;
}'

rm $LOG
