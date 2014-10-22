#!/bin/sh

HNAME=$(facter fqdn)

if [ -z $1 ]; then
        BASE=/etc/apache2/ssl
else
        BASE=$1
fi

if [ -f ${BASE}/$HNAME.key ]; then
        echo "WARN: key ${BASE}/$HNAME.key already present"
        exit 1
fi

echo "INFO: generating ${BASE}/$HNAME.key"
if [ ! -d ${BASE} ]; then
        mkdir -p ${BASE}
fi
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -keyout ${BASE}/$HNAME.key -out ${BASE}/$HNAME.crt -subj "/CN=$HNAME/"
cp ${BASE}/$HNAME.crt ${BASE}/cachain.pem
chmod 640 ${BASE}/*

