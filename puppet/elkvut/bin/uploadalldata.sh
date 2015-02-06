sh /puppet/elkvut/bin/forall.sh 'sh /puppet/bootstrap.install.sh 1>/dev/null'
sh /puppet/elkvut/bin/forall.sh 'ruby /puppet/elkvut/bin/describe.rb'
sh /puppet/elkvut/bin/show_nodes.sh

for all in $(find /data/data/ -type f | head -n2); do 
	time sh netflow/bin/send.sh -f $all
done
