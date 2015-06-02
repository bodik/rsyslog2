#!/bin/sh 

. /puppet/metalib/lib.sh

INSTALL_DIR=/opt/kippo
for all in $(cat $INSTALL_DIR/data/userdb.txt); do
	U=$(echo $all | awk -F':' '{print $1}')
	P=$(echo $all | awk -F':' '{print $3}')
	medusa -h $(facter ipaddress) -u $U -p $P -M ssh -n 45356 | grep "ACCOUNT FOUND" 1>/dev/null
	if [ $? -ne 0 ]; then
		rreturn 1 "$0 failed to login to hpkippo"
	fi
        sshpass -p $P ssh -o 'StrictHostKeyChecking=no' -o 'PubkeyAuthentication=no' -p 45356 -l $U $(facter ipaddress) 'wget http://www.google.com'
done

rreturn 0 "$0"
