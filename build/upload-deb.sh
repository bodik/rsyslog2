
FRONT='bodik@bodik.zcu.cz'
REPO="/afs/zcu.cz/users/b/bodik/public/metasw/rsyslog2/packages"

cd /tmp/build-area

ssh $FRONT "rm $REPO/\*"
scp * ${FRONT}:${REPO}/
ssh ${FRONT} "cd ${REPO} && dpkg-scanpackages ./ /dev/null | gzip > Packages.gz"
# >>> deb http://home.zcu.cz/~bodik/metasw/rsyslog2/packages ./



