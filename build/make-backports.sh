#!/bin/sh

cd /tmp || exit 1

mkdir build-area
cd build-area || exit 1


find . -name "libestr*deb" | grep "libestr*deb"
if [ $? = 1 ]; then
	apt-get source libestr
	cd $(find . -maxdepth 1 -type d -name "libestr*") || exit 1a
	sed -i '1 s/)/.rb20)/' debian/changelog
	dpkg-buildpackage -rfakeroot
	cd ..
	ls -l 
fi

find . -name "librelp*deb" | grep "librelp*deb"
if [ $? = 1 ]; then
	apt-get source librelp
	cd $(find . -maxdepth 1 -type d -name "librelp*") || exit 1
	sed -i '1 s/)/.rb20)/' debian/changelog
	dpkg-buildpackage -rfakeroot
	cd ..
	ls -l
fi

