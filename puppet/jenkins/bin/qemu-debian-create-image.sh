#!/bin/bash

clean_debian() {
	[ "$MNT_DIR" != "" ] && chroot $MNT_DIR umount /proc/ /sys/ /dev/ /boot/
	sleep 1s
	[ "$MNT_DIR" != "" ] && umount $MNT_DIR
	sleep 1s
	[ "$DISK" != "" ] && qemu-nbd -d $DISK
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

if [ $# -lt 3 ]
then
	echo "author: Kamil Trzcinski (http://ayufan.eu), bodik@cesnet.cz"
	echo "license: GPL"
	echo "usage: $0 <image-file> <hostname> <release> [optional debootstrap args]" 1>&2
	exit 1
fi

FILE=$1
HOSTNAME=$2
RELEASE=$3
shift 3

trap cancel INT

echo "Installing $RELEASE into $FILE..."

MNT_DIR=`tempfile`
rm $MNT_DIR
mkdir $MNT_DIR
DISK=

echo "Looking for nbd device..."

modprobe nbd max_part=16 || fail "failed to load nbd module into kernel"

for i in /dev/nbd*
do
	if qemu-nbd -c $i $FILE
	then
		DISK=$i
		break
	fi
done

[ "$DISK" = "" ] && fail "no nbd device available"

echo "Connected $FILE to $DISK"

echo "Partitioning $DISK..."
sfdisk $DISK -q -D -uM << EOF || fail "cannot partition $FILE"
,200,83,*
;
EOF

echo "Creating boot partition..."
mkfs.ext4 -q ${DISK}p1 || fail "cannot create /boot ext4"

echo "Creating root partition..."
mkfs.ext4 -q ${DISK}p2 || fail "cannot create / ext4"

echo "Mounting root partition..."
mount ${DISK}p2 $MNT_DIR || fail "cannot mount /"

echo "Installing Debian $RELEASE..."
debootstrap --include=less,vim,sudo,openssh-server,acpid $* $RELEASE $MNT_DIR http://ftp.cz.debian.org/debian || fail "cannot install $RELEASE into $DISK"

echo "Configuring system..."
cat <<EOF > $MNT_DIR/etc/fstab
/dev/sda1 /boot               ext4    sync 0       2
/dev/sda2 /                   ext4    errors=remount-ro 0       1
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

mount --bind /dev/ $MNT_DIR/dev || fail "cannot bind /dev"
chroot $MNT_DIR mount -t ext4 ${DISK}p1 /boot || fail "cannot mount /boot"
chroot $MNT_DIR mount -t proc none /proc || fail "cannot mount /proc"
chroot $MNT_DIR mount -t sysfs none /sys || fail "cannot mount /sys"
LANG=C DEBIAN_FRONTEND=noninteractive chroot $MNT_DIR apt-get install -y -q linux-image-amd64 grub-pc || fail "cannot install linux-image and grub"
chroot $MNT_DIR grub-install $DISK || fail "cannot install grub"
chroot $MNT_DIR update-grub || fail "cannot update grub"

sed -i "s|${DISK}p1|/dev/sda1|g" $MNT_DIR/boot/grub/grub.cfg
sed -i "s|${DISK}p2|/dev/sda2|g" $MNT_DIR/boot/grub/grub.cfg

#echo "Enter root password:"
#while ! chroot $MNT_DIR passwd root
#do
#	echo "Try again"
#done
chroot $MNT_DIR ssh-keygen -q -f /root/.ssh/id_rsa -N ''
chroot $MNT_DIR cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
cp $MNT_DIR/root/.ssh/id_rsa $FILE.id_rsa
cp $MNT_DIR/root/.ssh/id_rsa.pub $FILE.id_rsa.pub

echo "Finishing grub installation..."
grub-install $DISK --root-directory=$MNT_DIR --modules="biosdisk part_msdos" || fail "cannot reinstall grub"

echo "SUCCESS!"
clean_debian
exit 0
