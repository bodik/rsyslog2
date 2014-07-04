for all in `ls /var/lib/jenkins/jobs`; do
	echo $all
	mkdir jobs/$all
	cp /var/lib/jenkins/jobs/$all/config.xml jobs/$all
done
