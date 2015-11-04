#!/bin/sh

FQDN=$(facter fqdn)
DEST_DIR=/opt/hostcert

usage() { echo "Usage: $0 -s <WARDEN_SERVER> -d <DEST_DIR>" 1>&2; exit 1; }
while getopts "s:d:" o; do
    case "${o}" in
        s)
            WARDEN_SERVER=${OPTARG}
            ;;
        d)
            DEST_DIR=${OPTARG}
            ;;
        *)
            usage
        ;;
    esac
done
shift $((OPTIND-1))

if [ ! -d ${DEST_DIR} ]; then
        mkdir -p ${DEST_DIR}
fi
cd ${DEST_DIR} || exit 1


if [ -f $FQDN.crt ]; then
        echo "WARN: certificate $FQDN.crt already present in ${DEST_DIR}"
	find ${DEST_DIR} -ls
	exit 0
fi


echo "INFO: generating $FQDN.key"
openssl req -newkey rsa:4096 -nodes -keyout ${FQDN}.key -out ${FQDN}.csr -subj "/CN=${FQDN}/"

echo "INFO: signing $FQDN.csr"
#TODO: (in)secure
curl --insecure --data-urlencode @${FQDN}.csr "http://${WARDEN_SERVER}:45444/put_csr"
if [ $? -ne 0 ]; then
	echo "ERROR: cannot contact warden_ca"
	exit 1
fi

SIGNED=0
while [ $SIGNED -eq 0 ]; do
	curl -k "http://${WARDEN_SERVER}:45444/get_crt" >${FQDN}.crt 2>/dev/null
	openssl x509 -in ${FQDN}.crt 1>/dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
		SIGNED=1
	else
		echo "INFO: waiting for CA to sign our csr"
		rm ${FQDN}.crt
		sleep 1
	fi
done

curl -k "http://${WARDEN_SERVER}:45444/get_ca_crt" >cachain.pem 2>/dev/null
curl -k "http://${WARDEN_SERVER}:45444/get_crl" >ca.crl 2>/dev/null

find . -type f -exec chmod 644 {} \;

echo "INFO: done generating certificate from warden_ca"

