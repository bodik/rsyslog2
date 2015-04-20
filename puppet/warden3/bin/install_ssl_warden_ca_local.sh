#!/bin/sh

HNAME=$(facter fqdn)

if [ -z $1 ]; then
        BASE=/opt/warden_server/etc
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

cd /opt/warden_ca || exit 1

/opt/warden_ca/warden_ca.sh init
/opt/warden_ca/warden_ca.sh generate $HNAME
/opt/warden_ca/warden_ca.sh get_key $HNAME > $BASE/$HNAME.key
/opt/warden_ca/warden_ca.sh get_crt $HNAME > $BASE/$HNAME.crt
/opt/warden_ca/warden_ca.sh get_ca_crt $HNAME > $BASE/cachain.pem

/etc/init.d/apache2 restart

