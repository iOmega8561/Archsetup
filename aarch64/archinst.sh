#!/bin/bash
############################################################################
# CONFIGS

source configs.sh

############################################################################
############################################################################
############################################################################
############################################################################
############################################################################
############################################################################

function msg {
	echo -e "\033[0;32m==> SETUP: \033[0m\033[1m$1\033[0m"
}

############################################################################
# DATA CHECKS

msg "CHECK THIS DATA BEFORE CONTINUING"
printf "\nSETTINGS         VALUES
Locale:          $LANG $ENCODING
Keymap:          $KEYMAP
Timezone:        $TIMEZONE
Hostname:        $HOSTNAME
Zram:            $ZRAM
Zram size:       $ZRAMSIZE\n\n"
msg "PRESS ENTER TO CONTINUE"
read

if [ "$ZRAM" = false ] ; then
	msg "ZRAM IS DISABLED, YOU PROBABLY WANT A SWAP PARTITION"
	msg "PRESS ENTER TO CONTINUE"
	read
fi

msg "MAKE SURE THIS PARTITIONS ARE MOUNTED:"
printf "\nROOT partition to /mnt     [ TYPE 27 --> Linux root (ARM64) ]
EFI partition to /mnt/boot [ TYPE 1 --> EFI System Partition ]

Any other partition you'd want in your FSTAB
Swap partition will be auto-detected the correct GUID type is set\n\n"

msg "PRESS ENTER TO START THE INSTALLATION"
read

############################################################################
# NTP
timedatectl set-ntp true

############################################################################
# PACSTRAP

msg "EXECUTING PACSTRAP TO /mnt"
pacstrap /mnt base linux linux-firmware base-devel sudo networkmanager nano
sleep 3

############################################################################
# FSTAB

msg "GENERATING FSTAB"
genfstab -U /mnt > /mnt/etc/fstab
sleep 3

############################################################################
# SYSTEMD-BOOT INSTALLATION

msg "INSTALLING SYSTEMD-BOOT"
arch-chroot /mnt bootctl install
sleep 3

############################################################################
# SYSTEMD-BOOT CONFIGURATION

msg "WRITING BOOTLOADER CONFIGURATION"
tee /mnt/boot/loader/loader.conf <<- EOF >> /dev/null
	default normal
	timeout 3
EOF
sleep 3

############################################################################
# SYSTEMD-BOOT ENTRIES

msg "WRITING BOOTLOADER ENTRIES"

MOUNT=$(mount | grep " on /mnt ")
ROOT="${MOUNT%%on /mnt*}"

tee /mnt/boot/loader/entries/fallback.conf <<- EOF >> /dev/null
	title "Arch Linux (fallback initramfs)"
	linux /Image
	initrd /initramfs-$LINUX-fallback.img
	options root=$ROOT rw
EOF

tee /mnt/boot/loader/entries/normal.conf <<- EOF >> /dev/null
	title "Arch Linux"
	linux /Image
	initrd /initramfs-$LINUX.img
	options root=$ROOT rw
EOF
sleep 3

############################################################################
# LOCALES

msg "SETTING LOCALE $LANG"

tee -a /mnt/etc/locale.gen <<- EOF >> /dev/null
	$LANG $ENCODING
EOF

tee /mnt/etc/locale.conf <<- EOF >> /dev/null
	LANG=$LANG
EOF

tee /mnt/etc/vconsole.conf <<- EOF >> /dev/null
	KEYMAP=$KEYMAP
EOF

arch-chroot /mnt locale-gen
sleep 3

############################################################################
# TIME AND TIMEZONE

msg "SETTING SYSTEM TIME"

arch-chroot /mnt ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
sleep 1

arch-chroot /mnt hwclock --systohc
sleep 3

############################################################################
# HOSTNAME

msg "WRITING HOSTNAME TO /etc/hostname"

tee /mnt/etc/hostname <<- EOF >> /dev/null
	$HOSTNAME
EOF

############################################################################
# ZRAM

if [ "$ZRAM" = true ] ; then
	msg "INSTALLING ZRAM-GENERATOR"
	arch-chroot /mnt pacman -S --noconfirm zram-generator

	msg "WRITING ZRAM CONFIGURATION"
	tee /mnt/etc/systemd/zram-generator.conf <<- EOF >> /dev/null
		[zram0]
		zram-size = $ZRAMSIZE
	EOF
fi

############################################################################
# USER CREATION

msg "ENTER A VALID USERNAME: "
read NAME
arch-chroot /mnt useradd $NAME -m

msg "ENTER A VALID PASSWORD"
arch-chroot /mnt passwd $NAME

mkdir -p /mnt/etc/sudoers.d
tee /mnt/etc/sudoers.d/$NAME <<- EOF >> /dev/null
	$NAME ALL=(ALL) ALL
EOF

arch-chroot /mnt usermod -aG wheel $NAME

sleep 3

############################################################################
# TERMINATING

msg "SETUP PROCESS COMPLETED"
sleep 2
