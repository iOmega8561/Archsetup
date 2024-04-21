#!/bin/bash

source configs.sh
source functions.sh

############################################################################
############################################################################
############################################################################
############################################################################
############################################################################
############################################################################

############################################################################
# CPU CHECKS

machine_checks
msg 2 "CPU VENDOR $CPU_VENDOR, ARCH $CPU_ARCH"

############################################################################
# CONFIG CHECKS

msg 1 "CHECK THIS DATA BEFORE CONTINUING"
printf "\nSETTINGS         VALUES
Kernel:          $CFG_LINUX
Locale:          $CFG_LANG $CFG_ENCODING
Keymap:          $CFG_KEYMAP
Timezone:        $CFG_TIMEZONE
Hostname:        $CFG_HOSTNAME
Zram:            $CFG_ZRAM
Zram size:       $CFG_ZRAMSIZE\n\n"
msg 2 "PRESS ENTER TO CONTINUE"
read

if [[ "$CFG_ZRAM" = false ]] ; then
	msg 1 "ZRAM IS DISABLED, YOU PROBABLY WANT A SWAP PARTITION"
	msg 2 "PRESS ENTER TO CONTINUE"
	read
fi

msg 1 "MAKE SURE THESE PARTITIONS ARE MOUNTED:"
printf "\nROOT partition to /mnt     [ TYPE 23 --> Linux root (x86-64) ]
EFI partition to /mnt/boot [ TYPE 1 --> EFI System Partition ]

Any other partition you'd want in your FSTAB
Swap partition will be auto-detected if the correct GUID type is set\n\n"

############################################################################
# PARTITION CHECKS

partition_checks
msg 1 "DETECTED ROOT MOUNT: $PART_ROOT"
msg 1 "DETECTED BOOT MOUNT: $PART_BOOT"

msg 2 "PRESS ENTER TO START THE INSTALLATION"
read

############################################################################
# NTP
timedatectl set-ntp true

############################################################################
# PACSTRAP

msg 2 "EXECUTING PACSTRAP TO /mnt"
pacstrap /mnt base $CFG_LINUX $CFG_LINUX-headers linux-firmware \
			  base-devel sudo networkmanager nano $CPU_UCODE
sleep 3

############################################################################
# FSTAB

msg 2 "GENERATING FSTAB"
genfstab -U /mnt > /mnt/etc/fstab
sleep 3

############################################################################
# SYSTEMD-BOOT INSTALLATION

msg 2 "INSTALLING SYSTEMD-BOOT"
arch-chroot /mnt bootctl install
sleep 3

############################################################################
# SYSTEMD-BOOT CONFIGURATION

msg 2 "WRITING BOOTLOADER CONFIGURATION"
tee /mnt/boot/loader/loader.conf <<- EOF >> /dev/null
	default 01-arch
	timeout 3
EOF
sleep 3

############################################################################
# SYSTEMD-BOOT ENTRIES

msg 2 "WRITING BOOTLOADER ENTRIES"
boot_entries

############################################################################
# LOCALES

msg 2 "SETTING LOCALE $CFG_LANG"

tee -a /mnt/etc/locale.gen <<- EOF >> /dev/null
	$CFG_LANG $CFG_ENCODING
EOF

tee /mnt/etc/locale.conf <<- EOF >> /dev/null
	LANG=$CFG_LANG
EOF

tee /mnt/etc/vconsole.conf <<- EOF >> /dev/null
	KEYMAP=$CFG_KEYMAP
EOF

arch-chroot /mnt locale-gen
sleep 3

unset CFG_LANG
unset CFG_ENCODING
unset CFG_KEYMAP

############################################################################
# TIME AND TIMEZONE

msg 2 "SETTING SYSTEM TIME"

arch-chroot /mnt ln -sf /usr/share/zoneinfo/$CFG_TIMEZONE /etc/localtime
sleep 1

arch-chroot /mnt hwclock --systohc
sleep 3

unset CFG_TIMEZONE

############################################################################
# HOSTNAME

msg 2 "WRITING HOSTNAME TO /etc/hostname"

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

unset CFG_ZRAM
unset CFG_ZRAMSIZE

############################################################################
# USER CREATION

msg 1 "ENTER A VALID USERNAME: "
read USER_NAME
arch-chroot /mnt useradd $USER_NAME -m

msg 1 "ENTER A VALID PASSWORD"
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

msg 2 "SETUP PROCESS COMPLETED"
sleep 2
