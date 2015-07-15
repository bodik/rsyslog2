
FRONT='bodik@esb.metacentrum.cz'
REPO="/opt/packages"

cd /tmp/build-area

dpkg-scanpackages ./ /dev/null | gzip > Packages.gz

ssh $FRONT "find /opt/packages -type f -delete"
scp * ${FRONT}:${REPO}/
# >>> deb http://esb.metacentrum.cz/packages ./



