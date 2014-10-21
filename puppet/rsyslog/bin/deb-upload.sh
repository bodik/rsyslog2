
FRONT='bodik@bodik.zcu.cz'
REPO="/afs/zcu.cz/users/b/bodik/public/metasw/rsyslog2/packages"

cd /tmp/build-area

dpkg-scanpackages ./ /dev/null | gzip > Packages.gz

ssh $FRONT "find /afs/zcu.cz/users/b/bodik/public/metasw/rsyslog2/packages -type f -delete"
scp * ${FRONT}:${REPO}/
# >>> deb http://home.zcu.cz/~bodik/metasw/rsyslog2/packages ./



