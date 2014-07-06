echo "INFO: deleting old config"
for all in $(find jobs -mindepth 1 -maxdepth 1 -type d); do
	rm -r $all
done

for all in `ls /var/lib/jenkins/jobs`; do
	echo $all
	mkdir jobs/$all
	cp /var/lib/jenkins/jobs/$all/config.xml jobs/$all
done
