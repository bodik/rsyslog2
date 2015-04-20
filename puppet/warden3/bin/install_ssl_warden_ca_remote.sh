#!/bin/sh

HNAME=$(facter fqdn)

if [ -z $1 ]; then
        BASE=/etc/apache2/ssl
else
        BASE=$1
fi

WS=$(/puppet/metalib/avahi.findservice.sh _warden-server._tcp)
if [ -z "$WS" ]; then
	echo "ERROR: cannt discover warden_ca server"
	exit 1
fi

if [ -f ${BASE}/$HNAME.crt ]; then
        echo "WARN: key ${BASE}/$HNAME.crt already present"
	exit 1
fi

echo "INFO: generating ${BASE}/$HNAME.key"
if [ ! -d ${BASE} ]; then
        mkdir -p ${BASE}
fi
openssl req -newkey rsa:4096 -nodes -keyout ${BASE}/${HNAME}.key -out ${BASE}/${HNAME}.csr -subj "/CN=${HNAME}/"

echo "INFO: signing ${BASE}/$HNAME.csr"
curl -k --data-urlencode @${BASE}/${HNAME}.csr "http://${WS}:45444/putCsr"
if [ $? -ne 0 ]; then
	echo "ERROR: cannot contact warden_ca"
	exit 1
fi

SIGNED=0
while [ $SIGNED -eq 0 ]; do
	curl -k "http://${WS}:45444/getCertificate" >${BASE}/${HNAME}.crt 2>/dev/null
	openssl x509 -in ${BASE}/${HNAME}.crt 1>/dev/null
	if [ $? -eq 0 ]; then
		SIGNED=1
	else
		echo "INFO: waiting for CA to sign our csr"
		sleep 1
	fi
done

curl -k "http://${WS}:45444/getCaCertificate" >${BASE}/cachain.crt 2>/dev/null
curl -k "http://${WS}:45444/getCrl" >${BASE}/ca.crl 2>/dev/null

chmod 640 ${BASE}/*
echo "INFO: done generating certificate from warden_ca"
