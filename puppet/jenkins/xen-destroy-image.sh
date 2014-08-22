#!/bin/sh

HOSTNAME=$1
VGNAME=$(vgdisplay  | grep "VG Name" | awk '{print $3}')
FILE="/dev/mapper/${VGNAME}-${HOSTNAME}"

lvremove -f ${FILE}
if [ $? -ne 0 ]; then
	echo "ERROR: cannt remove volume ${FILE}"
	exit 1
fi
lvremove -f ${FILE}_swap
if [ $? -ne 0 ]; then
	echo "ERROR: cannt remove volume ${FILE}_swap"
	exit 1
fi

rm /etc/xen/boot/$HOSTNAME

return 0
