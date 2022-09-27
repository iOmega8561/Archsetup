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
# INIT

msg "CHECK CONFIGURATION"
printf "\nSETTINGS         VALUES
Locale:          $LANG $ENCODING
Keymap:          $KEYMAP
Timezone:        $TIMEZONE
Hostname:        $HOSTNAME
Zram size:       $ZRAMSIZE\n\n"
msg "PRESS ENTER TO CONFIRM"
read

msg "ENSURE PARTITIONS ARE MOUNTED:"
printf "\nROOT partition to /mnt (NO LUKS NO LVM)
EFI part to /mnt/boot (MUST BE EFI TYPE-UUID)
HOME part to /mnt/home (if present)\n\n"
msg "PRESS ENTER TO CONFIRM AND START"
read

msg "EXECUTING PACSTRAP TO /mnt"

timedatectl set-ntp true

pacstrap /mnt base linux linux-firmware base-devel sudo zram-generator networkmanager nano
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

msg "WRITING ZRAM CONFIGURATION"

tee /mnt/etc/systemd/zram-generator.conf <<- EOF >> /dev/null
	[zram0]
	zram-size = $ZRAMSIZE
EOF

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

msg "ADD MANUALLY NEW USER TO \"wheel\" GROUP IF NEEDED"

sleep 3

############################################################################
# TERMINATING

msg "SETUP PROCESS COMPLETED"
sleep 2
