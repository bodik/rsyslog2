#!/bin/sh
# will register sensor at warden server

usage() { echo "Usage: $0 -s <WARDEN_SERVER> -n <SENSOR_NAME> -d <DEST_DIR>" 1>&2; exit 1; }
while getopts "s:n:d:" o; do
    case "${o}" in
        s)
            WARDEN_SERVER=${OPTARG}
            ;;
        d)
            DEST_DIR=${OPTARG}
            ;;
        n)
            SENSOR_NAME=${OPTARG}
            ;;
        *)
            usage
        ;;
    esac
done
shift $((OPTIND-1))


#if tagfile exist, a sensor is probably already registred, this is just puppet helper conditional
if [ -f $DEST_DIR/registered-at-warden-server ]; then
	exit 0
fi

curl --silent --write-out '%{http_code}' "http://${WARDEN_SERVER}:45444/register_sensor?sensor_name=${SENSOR_NAME}" | grep 200 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
	touch ${DEST_DIR}/registered-at-warden-server
	exit 0
else
	echo "ERROR: cannt register at warden server"
	exit 1
fi

