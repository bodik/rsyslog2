#!/bin/sh

. /puppet/metalib/bin/lib.sh

python -c 'print "JDWP-Handshake\x00\x00\x00\x14\x00\x00\x00\x01\x00\x0f\x0f\x41\x55\x54\x4f\x54\x45\x53\x54"' | nc localhost 58000 | grep "AUTOTEST"

if [ $? -ne 0 ]; then
        rreturn 2 "$0 failed to jdwpd handshake"
fi 

rreturn 0 "$0"
