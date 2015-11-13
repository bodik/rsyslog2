#!/bin/sh 

. /puppet/metalib/bin/lib.sh

INSTALL_DIR=/opt/cowrie

for all in $(cat $INSTALL_DIR/data/userdb.txt | grep -v "^#" ); do
	U=$(echo $all | awk -F':' '{print $1}')
	P=$(echo $all | awk -F':' '{print $3}')
	medusa -h $(facter ipaddress) -u $U -p $P -M ssh -n 45356 | grep "ACCOUNT FOUND" 1>/dev/null
	if [ $? -ne 0 ]; then
		rreturn 1 "$0 failed to login to hpcowrie"
	fi
        sshpass -p $P ssh -o 'StrictHostKeyChecking=no' -o 'PubkeyAuthentication=no' -o 'UserKnownHostsFile=/dev/null' -p 45356 -l $U $(facter ipaddress) 'wget http://www.google.com'
	if [ $? -ne 0 ]; then
		rreturn 1 "$0 failed"
	fi
done

rreturn 0 "$0"
