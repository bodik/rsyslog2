#!/bin/sh

HNAME=$(facter fqdn)

if [ -z $1 ]; then
        BASE=/etc/apache2/ssl
else
        BASE=$1
fi

if [ ! -d ${BASE} ]; then
        mkdir -p ${BASE}
fi
cd ${BASE} || exit 1


WS=$(/puppet/metalib/avahi.findservice.sh _warden-server._tcp)
if [ -z "$WS" ]; then
	echo "ERROR: cannt discover warden_ca server"
	exit 1
fi

if [ -f $HNAME.crt ]; then
        echo "WARN: certificate $HNAME.crt already present in ${BASE}"
	find ${BASE} -ls
	exit 0
fi

echo "INFO: generating $HNAME.key"
openssl req -newkey rsa:4096 -nodes -keyout ${HNAME}.key -out ${HNAME}.csr -subj "/CN=${HNAME}/"

echo "INFO: signing $HNAME.csr"
curl -k --data-urlencode @${HNAME}.csr "http://${WS}:45444/putCsr"
if [ $? -ne 0 ]; then
	echo "ERROR: cannot contact warden_ca"
	exit 1
fi

SIGNED=0
while [ $SIGNED -eq 0 ]; do
	curl -k "http://${WS}:45444/getCertificate" >${HNAME}.crt 2>/dev/null
	openssl x509 -in ${HNAME}.crt 1>/dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
		SIGNED=1
	else
		echo "INFO: waiting for CA to sign our csr"
		rm ${HNAME}.crt
		sleep 1
	fi
done

curl -k "http://${WS}:45444/getCaCertificate" >cachain.pem 2>/dev/null
curl -k "http://${WS}:45444/getCrl" >ca.crl 2>/dev/null

find . -type f -exec chmod 640 {} \;

echo "INFO: done generating certificate from warden_ca"

