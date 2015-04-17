apt-get update
apt-get install -y git puppet

if [ ! -d /puppet ]; then
        cd /
        git clone http://esb3.metacentrum.cz/wardenb.git
        ln -sf /wardenb/puppet /puppet
else
        cd /puppet
        git remote set-url origin http://esb3.metacentrum.cz/wardenb.git
        git pull
fi

cd /puppet && git remote set-url origin bodik@esb3.metacentrum.cz:/data/wardenb.git

