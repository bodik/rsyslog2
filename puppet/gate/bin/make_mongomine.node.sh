ssh root@$1 'wget http://esb.metacentrum.cz/rsyslog2.git/bootstrap.install.sh && sh bootstrap.install.sh; cd /puppet; sh phase2.install.sh; sh mongomine.install.sh; sh mongomine/tests/mongomine.sh'
pa.sh -e "include mongomine::rsyslogwebproxy"
