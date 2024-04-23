#!/usr/bin/env bash
# Copyright (C) 2024  Giuseppe Rocco
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

source configs.sh
source functions.sh

############################################################################
############################################################################
############################################################################

check_machine
log 2 "CPU VENDOR $CPU_VENDOR, ARCH $CPU_ARCH"

############################################################################
# CONFIG CHECKS

log 1 "CHECK THIS DATA BEFORE CONTINUING"
printf "\nSETTINGS         VALUES
Kernel:          $CFG_LINUX
Locale:          $CFG_LANG $CFG_ENCODING
Keymap:          $CFG_KEYMAP
Timezone:        $CFG_TIMEZONE
Hostname:        $CFG_HOSTNAME
Zram:            $CFG_ZRAM
Zram size:       $CFG_ZRAMSIZE\n\n"
log 2 "PRESS ENTER TO CONTINUE"
read

log 1 "MAKE SURE THESE PARTITIONS ARE MOUNTED:"
printf "\nROOT partition to /mnt     [ TYPE 23 --> Linux root (x86-64) ]
EFI partition to /mnt/boot [ TYPE 1 --> EFI System Partition ]

Any other partition you'd want in your FSTAB
Swap partition will be auto-detected if the correct GUID type is set\n\n"

############################################################################
# PARTITION CHECKS

check_mounts

if [[ $? -eq 1 ]]
then
	log 0 "COULD NOT VERIFY PARTITION MOUNTS"
	exit 1
fi

log 1 "DETECTED ROOT MOUNT: $PART_ROOT"
log 1 "DETECTED BOOT MOUNT: $PART_BOOT"

log 2 "PRESS ENTER TO START THE INSTALLATION"
read

############################################################################
# NTP
timedatectl set-ntp true

############################################################################
# PACSTRAP

log 2 "EXECUTING PACSTRAP TO /mnt"
pacstrap /mnt base \
			  $CFG_LINUX \
			  $CFG_LINUX-headers \
			  linux-firmware \
			  base-devel \
			  sudo \
			  networkmanager \
			  nano \
			  $CPU_UCODE
sleep 3

############################################################################
# FSTAB

log 2 "GENERATING FSTAB"
genfstab -U /mnt > /mnt/etc/fstab
sleep 3

############################################################################
# SYSTEMD-BOOT

log 2 "INSTALLING SYSTEMD-BOOT"
arch-chroot /mnt bootctl install
sleep 3

log 2 "WRITING BOOTLOADER CONFIGURATION"
config_bootloader "$CFG_LINUX" "$PART_ROOT"
sleep 3

############################################################################
# LOCALES

log 2 "SETTING LOCALE $CFG_LANG"
config_localization "$CFG_LANG" "$CFG_ENCODING" "$CFG_KEYMAP"
sleep 3

############################################################################
# TIME AND TIMEZONE

log 2 "SETTING SYSTEM TIME"

arch-chroot /mnt ln -sf /usr/share/zoneinfo/$CFG_TIMEZONE /etc/localtime
sleep 1

arch-chroot /mnt hwclock --systohc
sleep 3

unset CFG_TIMEZONE

############################################################################
# HOSTNAME

log 2 "WRITING HOSTNAME TO /etc/hostname"

tee /mnt/etc/hostname <<- EOF >> /dev/null
	$CFG_HOSTNAME
EOF

unset CFG_HOSTNAME

############################################################################
# ZRAM

if [ "$CFG_ZRAM" = true ] ; then
	msg 2 "INSTALLING ZRAM-GENERATOR"
	arch-chroot /mnt pacman -S --noconfirm zram-generator

	msg 2 "WRITING ZRAM CONFIGURATION"
	tee /mnt/etc/systemd/zram-generator.conf <<- EOF >> /dev/null
		[zram0]
		zram-size = $CFG_ZRAMSIZE
	EOF
fi

############################################################################
# USER CREATION

log 1 "ENTER A VALID USERNAME: "
read USER_NAME
arch-chroot /mnt useradd $USER_NAME -m

log 1 "ENTER A VALID PASSWORD"
arch-chroot /mnt passwd $USER_NAME

mkdir -p /mnt/etc/sudoers.d
tee /mnt/etc/sudoers.d/$USER_NAME <<- EOF >> /dev/null
	$USER_NAME ALL=(ALL) ALL
EOF

arch-chroot /mnt usermod -aG wheel $USER_NAME

sleep 3

unset USER_NAME

############################################################################
# TERMINATING

log 2 "SETUP PROCESS COMPLETED"
sleep 2
exit 0