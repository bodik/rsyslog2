#!/bin/sh
#
# Copyright (C) 2011-2015 Cesnet z.s.p.o
# Use of this source is governed by a 3-clause BSD-style license, see LICENSE file.
# modified by bodik@cesnet.cz

#if [ "$#" -ne 6 ]; then
#    echo "Run me like:"
#    echo "${0##*/} 'https://warden-hub.example.org/warden3' org.example.warden.client 'ToPsEcReT' key.pem cert.pem tcs-ca-bundle.pem"
#    exit 1
#fi
. /puppet/metalib/bin/lib.sh
tmpfile=/tmp/warden-server.selftest

url="https://$(facter fqdn):45443/warden3"
client="$(echo $(facter fqdn) | awk '{n=split($0,A,".");S=A[n];{for(i=n-1;i>0;i--)S=S"."A[i]}}END{print S}').puppet_test_client"
secret=""
keyfile="/opt/hostcert/$(facter fqdn).key"
certfile="/opt/hostcert/$(facter fqdn).crt"
cafile="/opt/hostcert/cachain.pem"


echo "Test  404"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/blefub?client=$client&secret=$secret" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"error": 404' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  404"
fi

echo "Test  404"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/?client=$client&secret=$secret" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"error": 404' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  404"
fi

echo "Test  403 - no secret"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents?client=$client" \
    --silent --show-error
echo

echo "Test  403 - no client, no secret"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents" \
    --silent --show-error
echo

echo "Test  403 - wrong client"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents?client=asdf.blefub" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"error": 403' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  403 - wrong client"
fi

echo "Test  403 - wrong client, right secret"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents?client=asdf.blefub&secret=$secret" \
    --silent --show-error
echo

echo "Test  403 - right client, wrong secret"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents?client=$client&secret=ASDFblefub" \
    --silent --show-error
echo

echo "Test - no client, but secret, should be ok"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents?secret=$secret" \
    --silent --show-error
echo

echo "Test  Deserialization"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    --data '{#$%^' \
    "$url/getEvents?client=$client&secret=$secret" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"error": 400' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  Deserialization"
fi

echo "Test  Called with unknown category"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents?client=$client&secret=$secret&cat=bflm" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"error": 422' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  Called with unknown category"
fi

echo "Test  Called with both cat and nocat"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents?client=$client&secret=$secret&cat=Other&nocat=Test" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"error": 422' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  Called with both cat and nocat"
fi

echo "Test  Invalid data for getEvents - silently discarded"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    --data '[1]' \
    "$url/getEvents?client=$client&secret=$secret" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"events": \[' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  Invalid data for getEvents - silently discarded"
fi

echo "Test  Called with internal args - just in log"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents?client=$client&secret=$secret&self=test" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"events": \[' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  Called with internal args - just in log"
fi

echo "Test  Called with superfluous args - just in log"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents?client=$client&secret=$secret&bad=guy" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"events": \[' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  Called with superfluous args - just in log"
fi

echo "Test  getEvents with no args - should be OK"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents?client=$client&secret=$secret" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"events": \[' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  Called with superfluous args - just in log"
fi

echo "Test  getEvents - should be OK"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getEvents?client=$client&secret=$secret&count=3&id=10" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"events": \[' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  getEvents - should be OK"
fi

echo "Test  getDebug"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getDebug?client=$client&secret=$secret" \
    --silent --show-error
echo

echo "Test  getInfo"
curl \
    --key $keyfile \
    --cert $certfile \
    --cacert $cafile \
    --connect-timeout 3 \
    --request POST \
    "$url/getInfo?client=$client&secret=$secret" \
    --silent --show-error \
> $tmpfile
cat $tmpfile
echo
grep '"version": "3.' $tmpfile 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
	rreturn 1 "$0 Test  getInfo"
fi

rreturn 0 "$0"
