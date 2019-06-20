. common/perform-chroot.sh

mv /etc/fstab{,.org}
cat /etc/fstab.org | awk '/\/ /{print}' >> /etc/fstab
cat /etc/fstab.org | awk '/\/boot /{print}' >> /etc/fstab
cat /etc/fstab

. common/exit-chroot.sh
. common/umount-rescue.sh