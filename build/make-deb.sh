#!/bin/sh

cd /tmp || exit 1

if [ ! -d collab-maint-rsyslog ]; then
	git clone http://home.zcu.cz/~bodik/meta/git/collab-maint-rsyslog
	cd collab-maint-rsyslog
	git remote set-url origin --push bodik@bodik.zcu.cz:/afs/zcu.cz/users/b/bodik/public/meta/git/collab-maint-rsyslog
else
	cd collab-maint-rsyslog
	git pull
fi
#git remote set-url origin bodik@bodik.zcu.cz:/afs/zcu.cz/users/b/bodik/public/meta/git/collab-maint-rsyslog

git checkout debian/7.6.3-3.rb20
git-buildpackage --git-export-dir=../build-area/ -us -uc --git-debian-branch=debian/7.6.3-3.rb20


