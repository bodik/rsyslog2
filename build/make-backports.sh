#!/bin/sh

backport() {
	#src balik se jmenuje jinak nez vysledek, peklo
	PKG=$1
	DIR=$2
	
	find . -name "${PKG}*deb" | grep "${PKG}*deb"
	if [ $? = 1 ]; then
		apt-get source ${PKG}
		cd $(find . -maxdepth 1 -type d -name "${DIR}*") || exit 1
		grep ".rb20" debian/changelog 1>/dev/null 2>/dev/null
		if [ $? -eq 1 ]; then
			sed -i '1 s/)/.rb20)/' debian/changelog
		fi
		dpkg-buildpackage -rfakeroot
		cd ..
		ls -l 
	fi
}

cd /tmp || exit 1

mkdir build-area
cd build-area || exit 1

backport libestr libestr
backport librelp librelp
backport liblogging-stdlog0 liblogging
backport libjson-c2 json-c
backport init-system-helpers init-system-helpers

