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