#!/bin/sh
#time bash metalib/bin/benchmark_node.sh 1>/tmp/benchmark.log 2>&1

#very derty prep
puppet apply -e 'package { ["sysbench", "lshw"]: ensure => installed, }'

echo "== h2. DESCRIPTION BEGIN"
ruby /puppet/metalib/bin/describe_node.rb
echo "== DESCRIPTION END"

echo "== h2. BENCHMARKTEST BEGIN"
#test
for i in cpu threads mutex memory; do
        sysbench --test=$i run
done

BENCHDIR=/scratch/rsyslog2-cluster-fileio-benchmark.$$


mkdir -p $BENCHDIR
cd $BENCHDIR || exit 1
sysbench --num-threads=8 --test=fileio --file-total-size=1G --file-test-mode=rndrw prepare
sysbench --num-threads=8 --test=fileio --file-total-size=1G --file-test-mode=rndrw run
sysbench --num-threads=8 --test=fileio --file-total-size=1G --file-test-mode=rndrw cleanup
rm -rf $BENCHDIR

echo "== BENCHMARKTEST END"
