for all in $(cat /puppet/elkvut/nodes_esd); do
	ssh root@$all $1
done
