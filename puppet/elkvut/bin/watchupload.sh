watch '
	sh /puppet/elkvut/bin/el_inspeed.sh;
	echo "=======================";
	sh /puppet/elkvut/bin/show_nodes.sh;
	echo "=======================";
	echo -n "uploaded so far:"; grep "== uploading" /tmp/upload.log | wc -l; 
	echo "=======================";
	tail /tmp/upload.log
'
