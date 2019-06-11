#!/bin/bash

#Discover the stucture of the os-data-disk
==========================================

#get boot flaged partition
#-------------------------
boot_part=$(fdisk -l /dev/sdc | awk '$2 ~ /\*/ {print $1}')

#get partitions of sdc
#---------------------
partitions=$(fdisk -l /dev/sdc | awk '/^\/dev\/sdc/ {print $1}')

#get the root partition
#-----------------------
rescue_root=$(echo $partitions | sed "s|$boot_part||g")



#Mount the root part
#====================

mkdir /mnt/rescue-root
mount -o nouuid $rescue_root /mnt/rescue-root

#Mount the boot part
#===================

mkdir /mnt/rescue-boot
mount -o nouuid $boot_part /mnt/rescue-boot



#Mount the support filesystems
#==============================
#see also http://linuxonazure.azurewebsites.net/linux-recovery-using-chroot-steps-to-recover-vms-that-are-not-accessible/
cd /mnt/rescue-root
mount -t proc proc proc
mount -t sysfs sys sys/
mount -o bind /dev dev/
mount -o bind /dev/pts dev/pts/

chroot /mnt/rescue-root

mv /etc/fstab{,.org}
cat /etc/fstab.org | awk '/\/ /{print}' >> /etc/fstab
cat /etc/fstab.org | awk '/\/boot /{print}' >> /etc/fstab
cat /etc/fstab


exit
cd /
umount /mnt/rescue-root/proc
umount /mnt/rescue-rootsys
umount /mnt/rescue-root/dev/pts
umount /mnt/rescue-root/dev
umount /mnt/rescue-boot
umount /mnt/rescue-root








