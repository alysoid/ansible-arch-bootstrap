# Arch Linux Bootstrap

Collection of Ansible tasks to manage these settings:

- Timezone with `community.general.timezone` module.
- Hostname with `ansible.builtin.hostname` module.
- `/etc/hosts` with optimized IPv4 and IPv6 defaults.
- Locales with `ansible.builtin.locale_gen` module.
- Custom languages and keymaps with `localectl`.

It also includes tasks and scripts to install a new Arch Linux system:

- Initialize, partition and format the system disk.
- Mount `boot` partition and `root` Btrfs with subvolumes.
- Create `swapfile` on `@swap` subvolume in `root` partition.
- Install the Linux kernel and custom essential packages.
- Install and configure `systemd-boot` EFI boot manager.

When the target is an existing Arch Linux system, these tasks are ignored.

## Install Arch Linux with Ansible

See [`INSTALL.md`](INSTALL.md) for details.

## Role variables

See [`defaults/main.yml`](defaults/main.yml) for details.
