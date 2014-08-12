cd /tmp
git clone git://anonscm.debian.org/collab-maint/rsyslog.git
git-buildpackage --git-export-dir=../build-area/ -us -uc --git-debian-branch=bodik
