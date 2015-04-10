#!/bin/bash

clean_debian() {
	cd /tmp || exit 1
	[ "$MNT_DIR" != "" ] && chroot $MNT_DIR umount /proc/ /sys/ /dev/
	sleep 1s
	[ "$MNT_DIR" != "" ] && umount $MNT_DIR
	sleep 1s
	[ "$MNT_DIR" != "" ] && rm -r $MNT_DIR
}

fail() {
	clean_debian
	echo ""
	echo "FAILED: $1"
	exit 1
}

cancel() {
	fail "CTRL-C detected"
}

if [ $# -lt 2 ]
then
	echo "author: Kamil Trzcinski (http://ayufan.eu), bodik@cesnet.cz, majlen@civ.zcu.cz"
	echo "license: GPL"
	echo "usage: $0 <hostname> <release> [optional debootstrap args]" 1>&2
	exit 1
fi

HOSTNAME=$1
RELEASE=$2
shift 2

trap cancel INT

VGNAME=$(vgdisplay  | grep "VG Name" | awk '{print $3}')

FILE="/dev/mapper/${VGNAME}-${HOSTNAME}"

echo "Installing $RELEASE into $FILE..."

MNT_DIR=`tempfile`
rm $MNT_DIR
mkdir $MNT_DIR

lvremove -f ${FILE}
lvremove -f ${FILE}_swap

lvcreate -L20G -n ${HOSTNAME} ${VGNAME} || exit 1
mkfs.ext4 ${FILE}
lvcreate -L2G -n ${HOSTNAME}_swap ${VGNAME} || exit 1
mkswap ${FILE}_swap

mount ${FILE} $MNT_DIR || exit 1
cd $MNT_DIR || exit 1



echo "Installing Debian $RELEASE..."
debootstrap --include=less,vim,sudo,openssh-server,acpid,ca-certificates $* $RELEASE $MNT_DIR http://ftp.cz.debian.org/debian || fail "cannot install $RELEASE into $FILE"

echo "Configuring system..."
cat <<EOF > $MNT_DIR/etc/fstab
/dev/xvda /                   ext4    errors=remount-ro 0       1
/dev/xvdb none                swap    sw                0       1
EOF

echo $HOSTNAME > $MNT_DIR/etc/hostname

cat <<EOF > $MNT_DIR/etc/hosts
127.0.0.1       localhost
127.0.1.1 		$HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

cat <<EOF > $MNT_DIR/etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

cat <<EOF >> $MNT_DIR/etc/sysctl.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

chroot $MNT_DIR perl -pi -e 's/tty1/hvc0/' /etc/inittab

mount --bind /dev/ $MNT_DIR/dev || fail "cannot bind /dev"
chroot $MNT_DIR mount -t proc none /proc || fail "cannot mount /proc"
chroot $MNT_DIR mount -t sysfs none /sys || fail "cannot mount /sys"
LANG=C DEBIAN_FRONTEND=noninteractive chroot $MNT_DIR apt-get install -y -q linux-image-amd64 grub-pc || fail "cannot install linux-image and grub"



#TODO: toto nefunguje pri instalaci na LVM, potrebujeme to vubec kdyz nepozuivamke pygrub?
###chroot $MNT_DIR grub-install $FILE || fail "cannot install grub"
###chroot $MNT_DIR update-grub || fail "cannot update grub"
##echo "Finishing grub installation..."
##grub-install $FILE --root-directory=$MNT_DIR --modules="biosdisk part_msdos" || fail "cannot reinstall grub"
#####sed -i "s|${FILE}p1|/dev/sda1|g" $MNT_DIR/boot/grub/grub.cfg
#####sed -i "s|${FILE}p2|/dev/sda2|g" $MNT_DIR/boot/grub/grub.cfg



mkdir $MNT_DIR/root/.ssh/
chmod 700 $MNT_DIR/root/.ssh/
cp /dev/shm/sshkey.pub $MNT_DIR/root/.ssh/authorized_keys


echo "ktadd -k $MNT_DIR/etc/krb5.keytab host/${HOSTNAME}@ZCU.CZ" | kadmin -k -t /etc/krb5.keytab host/$(hostname -f)@ZCU.CZ
cat << __EOF__ >> $MNT_DIR/root/.k5login
bodik/root@ZCU.CZ
majlen@ZCU.CZ
host/jstagbob.civ.zcu.cz@ZCU.CZ
svamberg/root@ZCU.CZ
obal/root@ZCU.CZ
lvalenta@ZCU.CZ
carney@ZCU.CZ
__EOF__



MYMAC=$(host -t TXT $HOSTNAME  | grep mymac | sed 's/.*mymac \(.*\)"/\1/')
cat << __EOF__ > /etc/xen/boot/${HOSTNAME}
#----------------------------------------------------------------------------
# Standard variables
kernel = "/boot/vmlinuz-3.2.0-4-amd64"
ramdisk = "/boot/initrd.img-3.2.0-4-amd64"
memory = 2048
name = "${HOSTNAME}"
vcpus = 4
vif = ['mac=${MYMAC}, bridge=br52']
disk = [ 'phy:${FILE},xvda,w',
         'phy:${FILE}_swap,xvdb,w'
]
root = "/dev/xvda ro"
extra = "clocksource=xen"
__EOF__

echo "INFO: $0 done"
echo "INFO: xm create boot/${HOSTNAME} -c"

echo "SUCCESS!"
clean_debian


exit 0
