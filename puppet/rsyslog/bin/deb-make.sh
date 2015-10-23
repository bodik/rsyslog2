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
	RBVERSION=debian/8.4.2+deb8u1.rb31
fi
git checkout $RBVERSION
git-buildpackage --git-export-dir=../build-area/ -us -uc --git-debian-branch=$RBVERSION

