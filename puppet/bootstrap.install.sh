apt-get update
apt-get install -y git puppet

if [ ! -d /puppet ]; then
	cd /
	git clone http://esb.metacentrum.cz/rsyslog2.git
	ln -sf /rsyslog2/puppet /puppet
else
	cd /puppet
	git remote set-url origin http://esb.metacentrum.cz/rsyslog2.git
	git pull
fi

cd /puppet && git remote set-url origin bodik@esb.metacentrum.cz:/data/rsyslog2.git

