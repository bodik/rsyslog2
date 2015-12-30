
FRONT='bodik@esb.metacentrum.cz'
REPO="/data/rsyslog2-packages"

cd /tmp/build-area

dpkg-scanpackages ./ /dev/null | gzip > Packages.gz

ssh $FRONT "find ${REPO} -type f -delete"
scp * ${FRONT}:${REPO}/
# >>> deb http://esb.metacentrum.cz/rsyslog2-packages ./



