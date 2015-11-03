#!/bin/sh

cd /tmp || exit 1

if [ ! -d collab-maint-rsyslog ]; then

	# repozitar vytvoreny clonem z collabu
	# git://anonscm.debian.org/collab-maint/rsyslog.git
	# musi byt navic nastaveny jako 'git config remote.origin.fetch 'refs/heads/*:refs/heads/*''
	# aby se do nej daly natahovat nove veci z upstreamu upstreamu 'git fetch --all'
	# klasicky post update hook
	# po fetchi se navic musi rucne dat 'git update-server-info' protoze na fetch neni hook
	#git clone http://home.zcu.cz/~bodik/meta/git/collab-maint-rsyslog
	git clone http://esb.metacentrum.cz/collab-maint-rsyslog.git

	cd collab-maint-rsyslog
	git remote set-url origin --push bodik@esb.metacentrum.cz:/data/collab-maint-rsyslog.git
else
	cd collab-maint-rsyslog
	git pull
fi

if [ -z "$RBVERSION" ]; then
	#by default we build latest revision found in collab sources
	RBVERSION=$(git branch | grep "\.rb[0-9]\+" | sort -rn | head -1 | rev | awk '{print $1}' | rev)
	
fi
git checkout $RBVERSION
git-buildpackage --git-export-dir=../build-area/ -us -uc --git-debian-branch=$RBVERSION

