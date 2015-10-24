dpkg --purge logstash logstash-contrib; rm -r /etc/logstash/; rm /etc/apt/sources.list.d/logstash.list; apt-get clean; apt-get update
