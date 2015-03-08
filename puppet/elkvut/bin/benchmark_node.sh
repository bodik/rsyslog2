#!/bin/sh

#very derty prep
puppet apply -e 'package { "sysbench": ensure => installed, }'


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
