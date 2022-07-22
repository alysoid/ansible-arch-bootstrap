#!/bin/bash

[ -z $1 ] && printf "usage: init_disk.sh /dev/sdx\n" && exit 1;
[ ! -b $1 ] && printf "error: target disk does not exist!\n" && exit 1;

# Disk settings
root_device=$1
boot_partition="$11"
root_partition="$12"
mountpoint="/mnt"
btrfs_opts="defaults,noatime,ssd,discard=async,compress=zstd:3"
swapfile_size="2000" # Size in MiB

#
# Partition the disks with sgdisk
#

# Clean the disk and create GPT partition table
wipefs -af $root_device
sgdisk -og $root_device

# Create partition 1: EFI boot @ 550 MiB
sgdisk -n 1:0:+550M -t 1:ef00 $root_device -c 1:"EFI system partition"

# Create partition 2: System @ Rest of disk
sgdisk -n 2:0:0 -t 2:8300 $root_device -c 2:"Linux filesystem"

#
# Format the partitions
#

# Format EFI partition as FAT32
mkfs.fat -F 32 $boot_partition -n "BOOT" -I

# Format system partition as btrfs
mkfs.btrfs $root_partition -L "ArchLinux" --force

# Mount btrfs partition to $mountpoint
mount -t btrfs $root_partition $mountpoint

# Create btrfs subvolumes
btrfs subvolume create $mountpoint/@
btrfs subvolume create $mountpoint/@home
btrfs subvolume create $mountpoint/@cache
btrfs subvolume create $mountpoint/@log
btrfs subvolume create $mountpoint/@swap

# Create swapfile in btrfs @swap subvolume
# https://man.archlinux.org/man/btrfs.5#SWAPFILE_SUPPORT
# https://btrfs.wiki.kernel.org/index.php/Compression#Can_I_set_compression_per-subvolume.3F
chattr +C $mountpoint/@swap # Set NOCOW attribute
dd if=/dev/zero of=$mountpoint/@swap/swapfile bs=1M count=$swapfile_size status=progress
chmod 0600 $mountpoint/@swap/swapfile
mkswap -U clear $mountpoint/@swap/swapfile

# Unmount btrfs partition, we need '/@' subvolume as root
umount $mountpoint

#
# Mount the filesystems
#

# Mount btrfs subvolume '/@' as root and create subfolders
mount -o subvol=@,$btrfs_opts $root_partition $mountpoint
mkdir -p $mountpoint/{home,var/cache,var/log,swap}

# Mount EFI system partition
mount --mkdir $boot_partition $mountpoint/boot

# Mount all other subvolumes on created folders
mount -o subvol=@home,$btrfs_opts $root_partition $mountpoint/home
mount -o subvol=@cache,$btrfs_opts $root_partition $mountpoint/var/cache
mount -o subvol=@log,$btrfs_opts $root_partition $mountpoint/var/log
mount -o subvol=@swap,$btrfs_opts $root_partition $mountpoint/swap

# Enable swapfile with swapon
swapon $mountpoint/swap/swapfile
