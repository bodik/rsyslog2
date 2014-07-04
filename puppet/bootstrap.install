apt-get update
apt-get install -y git puppet

if [ ! -d /puppet ]; then
	cd /
	git clone https://home.zcu.cz/~bodik/meta/git/rsyslog2
	ln -sf /rsyslog2/puppet /puppet
else
	cd /puppet
	git remote set-url origin https://home.zcu.cz/~bodik/meta/git/rsyslog2
	git pull
fi

cd /puppet && git remote set-url origin bodik@bodik.zcu.cz:/afs/zcu.cz/users/b/bodik/public/meta/git/rsyslog2

