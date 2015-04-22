#!/bin/sh
# will auto register sensor at warden server

usage() {
	echo "$0 server sensor directory"
}

if [ -z "$1" ]; then
	echo "ERROR: no server specified"
fi

if [ -z "$2" ]; then
	echo "ERROR: no sensor specified"
fi

if [ -z "$3" ]; then
	echo "ERROR: no directory specified"
fi

WS=$1
SENSOR=$2
DIR=$3

if [ -f $DIR/registered-at-warden-server ]; then
	exit 0
fi

/usr/bin/curl -s -w '%{http_code}' "http://${1}:45444/registerSensor?s=${2}" | grep 200 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
	touch $3/registered-at-warden-server
	exit 0
else
	echo "ERROR: cannt register"
	exit 1
fi

