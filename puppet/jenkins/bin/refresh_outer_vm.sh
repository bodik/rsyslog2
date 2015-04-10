#!/bin/sh

if [ ! -d bob ]; then
	echo "ERROR: no Robert Jenkins found in cwd"
	exit 1
fi

rm -r bob
7z x debian-wheezy.7z
mv debian-wheezy bob
perl -pi -e 's/displayName = "debian-wheezy"/displayName = "bob"/' bob/debian-wheezy.vmx
perl -pi -e 's/memsize = ".*"/memsize = "4096"/' bob/debian-wheezy.vmx
echo 'vhv.enable = "TRUE"' >> bob/debian-wheezy.vmx
vmplayer bob/debian-wheezy.vmx
