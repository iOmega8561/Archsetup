# Archsetup
## Disclaimer
This is a learning project, and although i use it quite a lot without issues, it's really not production-ready so use it carefully.

## What's this?
This is a bash script that performs basic operations to install Arch Linux without all the hassle of having to remember what to do every once in a while. Since i needed to run some ARM64 machines, i decided to include both x86 and ARM64 versions of the exact same script.

## Who is this for?
This is for people, like myself, that can already install their system manually, but can't bother with having to check the official guide every time they forget something. Basic knowledge of the installation process is required.

## How to use?
This script is very simple, it in fact follows very closely the official [Arch Linux installation guide](https://wiki.archlinux.org/title/installation_guide). There is some basic configuration that can be achieved, such as hostname or linux kernel flavour. To do that, you just need to edit **configs.sh**.

### Requirements
First of all, the system should be booted from an Arch Linux installation media in UEFI mode. You can check that by entering the command ```ls /sys/firmware/efi/efivars/```. You should have a bunch of output lines.

#### Partitions
The script won't setup partitions, so you will need to do that yourself. EFI and ROOT partitions on a GPT table are required, but you can create other partitions if you need them, like a separate HOME. It is **VERY IMPORTANT** to correctly set GUID partition types for your partitions. A nice tool to do that is fdisk.

#### Swap
By default the script will setup zram for you. If you wish to not use zram, please create a swap partition with the correct GUID partition type and set **ZRAM = false** in the configuration file. The swap partition won't be included in the FSTAB but systemd will detect it's GUID info and mount it as swap.

#### Bootloader
Systemd-boot will be automatically installed and configured. This is why GUID partition types need to be correctly set.

### When ready to start
Clone this repository directly from the install media and run the script.
