# Archsetup
<p align="center">
  <img src="https://github.com/iOmega8561/Archsetup/blob/master/screenshot.png?raw=true" />
</p>

This is an Arch Linux installation script, that executes very basic system commands following the [Arch Linux installation guide](https://wiki.archlinux.org/title/installation_guide) principles very closely.

## Who is this for?
This is for people, like myself, that **can** perform a manual installation, but can't bother with having to check the official guide every time they forget something. Basic knowledge of the installation process is **required**, given that zero distaster recovery features are provided.

## How to use this script
#### UEFI
First of all, the system should be booted from an Arch Linux installation media in UEFI mode. You can check that by listing your efivars with this command ```ls /sys/firmware/efi/efivars/```. You should have a bunch of output lines.

#### Partitions
Since there are so many possible configurations when it comes to system drives, the user is required to set everything up according to their necessities. 
The only **very important** things to have:
1. ROOT volume mounted under /mnt
2. EFI system volume mounted under /mnt/boot
4. GUID partition type correctly set to 1 for your EFI volume

#### Swap
By default the script will setup zram for you. If you wish not to use zram, set **ZRAM = false** in *modules/config.sh*.
Any other swap configuration is up to you.

#### When ready to start
Clone this repository, configure your desired parameters in *modules/config.sh* and run ```./archlinux-setup.sh```.
