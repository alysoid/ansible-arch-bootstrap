# Arch Linux Bootstrap

Collection of Ansible tasks and scripts to bootstrap a new Arch Linux system.

- Initialize, partition and format the system disk.
- Mount `boot` partition and `root` Btrfs with subvolumes.
- Create `swapfile` on `@swap` subvolume in `root` partition.
- Install the Linux kernel and custom essential packages.
- Install and configure the `systemd-boot` EFI boot manager.

## Install Arch Linux with Ansible

When the Live CD is booted and an SSH server is operating on the target machine:

```shell
# On an existing Arch Linux system
$ sudo pacman -S ansible sshpass
$ ansible-playbook --user root --ask-pass -i {target_ip_address}, bootstrap.yml
```

Done. But first take a look at `defaults/main.yml` and carefully read the documentation below.

### Example Playbook

```yaml
# playbook.yml
- name: Arch Linux Bootstrap
  hosts: "{{ target_ip_address }}"
  roles:
    - { role: bootstrap, tags: [bootstrap] }
```

## SSH Connection

Install Arch Linux remotely using an SSH connection is very convenient:

1. You have access to copy/paste ability of an SSH client.
2. All the installation procedure is done from a confortable working environment.

### Prerequisites

These steps require physical access to the target machine.

1. Boot the [Arch Live CD/USB image](https://archlinux.org/download/) on the remote machine. This will log the user in as root.
2. Setup the network as suggested in [Installation guide#Connect to the internet](https://wiki.archlinux.org/title/Installation_guide#Connect_to_the_internet).
3. Run `passwd` to setup a root password needed for an SSH connection (default is empty).

In the Live CD environment, `PermitRootLogin yes` in [`/etc/ssh/sshd_config`](https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/configs/releng/airootfs/etc/ssh/sshd_config) should be already set and the OpenSSH daemon (`systemctl start sshd.service`) should be already started.

### Connection from the local machine

Connect to the target machine via SSH with `ssh root@{target_ip_address}`.

## Initialize system disk

This procedure is fully automated using a Bash script called via Ansible that will run when `bootstrap_init_disk` is `true`, but as a matter of caution this is `false` by default. Be sure you 100% understand how the `files/init_disk.sh` script works before enabling this function. In short, the script erase the target system disk, create a new GPT partition table, format partitions and mount file systems in `/mnt`.

You may prefer to do these steps manually or customize the script according to your preferences.

### Partition, format and mount

Following my preferences, the script creates this disk layout:

1. GPT Partition table with MBR protective
2. Partition 1: EFI fat32 @ 550 MiB (Label `BOOT`)
3. Partition 2: Btrfs @ Rest of disk (Label `ArchLinux`)

Next, it creates these subvolumes on the partition 2:

- `subvol=@` mounted on `/mnt`
- `subvol=@home` mounted on `/mnt/home`
- `subvol=@cache` mounted on `/mnt/var/cache`
- `subvol=@log` mounted on `/mnt/var/log`
- `subvol=@swap` mounted on `/mnt/swap` (with NOCOW attribute)

The `@swap` subvolume has a 2 GiB enabled `swapfile` inside and will be mounted with these options: `defaults,noatime,ssd,discard=async`. All the other subvolumes will have the same options plus `compress=zstd:3`.

## Install essential packages

Essential packages are installed using the `pacstrap` script as suggested by the official Arch Installation Guide beside the Linux kernel and processor microcode (AMD or Intel). These are the defaults:

```yaml
bootstrap_packages:
  - base
  - base-devel
  - efibootmgr
  - btrfs-progs
  - nfs-utils
  - usbutils
  - python
  - ansible
  - sudo
  - nano
  - man-db
  - man-pages
  - bash-completion

bootstrap_kernel: linux
```

The default EFI boot manager is `systemd-boot` ready to operate with a default `arch.conf` entry and an additional `arch-fallback.conf` entry with a timeout of 3 seconds.

## Final steps

When the bootstrap procedure is done, SSH into the machine and execute `arch-chroot /mnt` to check that everything is all right. It is recommended checking at least `/etc/fstab` and systemd-boot configuration files: `/boot/loader.conf`, `/boot/entries/arch.conf` before exiting the chroot environment with:

```shell
$ exit
$ swapoff -a
$ umount -R /mnt
$ systemctl reboot
```
