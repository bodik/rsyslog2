for all in $(cat /puppet/elkvut/nodes); do
	ssh root@$all $1
done
