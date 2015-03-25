ssh root@$1 'wget http://esb3.metacentrum.cz/rsyslog2.git/bootstrap.install.sh && sh bootstrap.install.sh; cd /puppet; sh phase2.install.sh; sh elk.install.sh'
