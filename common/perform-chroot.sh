# Perform chroot
. ./mount-rescue.sh
#Mount the support filesystems
#==============================
#see also http://linuxonazure.azurewebsites.net/linux-recovery-using-chroot-steps-to-recover-vms-that-are-not-accessible/
cd /mnt/rescue-root
mount -t proc proc proc
mount -t sysfs sys sys/
mount -o bind /dev dev/
mount -o bind /dev/pts dev/pts/

chroot /mnt/rescue-root