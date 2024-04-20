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

	code="0m"

	case $1 in
		2)
			code="32m"
			;;
		1)
			code="33m"
			;;
		0)
			code="31m"
			;;
		*)
			;;
	esac

	echo -e "\033[0;$code==> SETUP: \033[0m\033[1m$2\033[0m"
}

############################################################################
# MACHINE CHECKS

ARCH=$(uname -m)

CPUINFO_DUMP="$(cat /proc/cpuinfo | grep -m 1 vendor_id)"
CPU_VENDOR="${CPUINFO_DUMP#vendor_id*: }"

unset CPUINFO_DUMP

msg 2 "CPU VENDOR $CPU_VENDOR, ARCH $ARCH"

case $CPU_VENDOR in
	AuthenticAMD)
		export CPU_UCODE="amd-ucode"
		;;
	GenuineIntel)
		export CPU_UCODE="intel-ucode"
		;;
	*)
		;;
esac

if [ "$ARCH" != "x86_64" ] ; then
	export LINUX=linux
	unset CPU_UCODE
fi

############################################################################
# CONFIG CHECKS

msg 1 "CHECK THIS DATA BEFORE CONTINUING"
printf "\nSETTINGS         VALUES
Kernel:          $LINUX
Locale:          $LANG $ENCODING
Keymap:          $KEYMAP
Timezone:        $TIMEZONE
Hostname:        $HOSTNAME
Zram:            $ZRAM
Zram size:       $ZRAMSIZE\n\n"
msg 2 "PRESS ENTER TO CONTINUE"
read

if [ "$ZRAM" = false ] ; then
	msg 1 "ZRAM IS DISABLED, YOU PROBABLY WANT A SWAP PARTITION"
	msg 2 "PRESS ENTER TO CONTINUE"
	read
fi

msg 1 "MAKE SURE THIS PARTITIONS ARE MOUNTED:"
printf "\nROOT partition to /mnt     [ TYPE 23 --> Linux root (x86-64) ]
EFI partition to /mnt/boot [ TYPE 1 --> EFI System Partition ]

Any other partition you'd want in your FSTAB
Swap partition will be auto-detected if the correct GUID type is set\n\n"

############################################################################
# PARTITION CHECKS

MOUNT_DUMP=$(mount | grep " on / ")
ROOT_NAME="${MOUNT_DUMP%%on /*}"

unset MOUNT_DUMP

MOUNT_DUMP=$(mount | grep " on /mnt/boot ")
BOOT_NAME="${MOUNT_DUMP%%on /mnt/boot*}"

unset MOUNT_DUMP

msg 1 "DETECTED ROOT MOUNT: $ROOT_NAME"
msg 1 "DETECTED BOOT MOUNT: $BOOT_NAME"

msg 2 "PRESS ENTER TO START THE INSTALLATION"
read

############################################################################
# NTP
timedatectl set-ntp true

############################################################################
# PACSTRAP

msg 2 "EXECUTING PACSTRAP TO /mnt"
pacstrap /mnt base $LINUX $LINUX-headers linux-firmware base-devel sudo networkmanager nano $CPU_UCODE
sleep 3

unset CPU_UCODE

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

KERNEL_IMAGE="vmlinuz-$LINUX"

if [ -f /mnt/boot/Image ] ; then
	KERNEL_IMAGE="Image"
fi

tee /mnt/boot/loader/entries/02-arch-fallback.conf <<- EOF >> /dev/null
	title "Arch Linux (fallback initramfs)"
	linux /$KERNEL_IMAGE
	initrd /initramfs-$LINUX-fallback.img
	options root=$ROOT_NAME rw
	sort-key arch-fallback
EOF

tee /mnt/boot/loader/entries/01-arch.conf <<- EOF >> /dev/null
	title "Arch Linux"
	linux /$KERNEL_IMAGE
	initrd /initramfs-$LINUX.img
	options root=$ROOT_NAME rw
	sort-key arch
EOF

unset KERNEL_IMAGE
unset LINUX
unset ROOT_NAME

############################################################################
# LOCALES

msg 2 "SETTING LOCALE $LANG"

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

unset LANG
unset ENCODING
unset KEYMAP

############################################################################
# TIME AND TIMEZONE

msg 2 "SETTING SYSTEM TIME"

arch-chroot /mnt ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
sleep 1

arch-chroot /mnt hwclock --systohc
sleep 3

unset TIMEZONE

############################################################################
# HOSTNAME

msg 2 "WRITING HOSTNAME TO /etc/hostname"

tee /mnt/etc/hostname <<- EOF >> /dev/null
	$HOSTNAME
EOF

unset HOSTNAME

############################################################################
# ZRAM

if [ "$ZRAM" = true ] ; then
	msg 2 "INSTALLING ZRAM-GENERATOR"
	arch-chroot /mnt pacman -S --noconfirm zram-generator

	msg 2 "WRITING ZRAM CONFIGURATION"
	tee /mnt/etc/systemd/zram-generator.conf <<- EOF >> /dev/null
		[zram0]
		zram-size = $ZRAMSIZE
	EOF
fi

unset ZRAM
unset ZRAMSIZE

############################################################################
# USER CREATION

msg 1 "ENTER A VALID USERNAME: "
read NAME
arch-chroot /mnt useradd $NAME -m

msg 1 "ENTER A VALID PASSWORD"
arch-chroot /mnt passwd $NAME

mkdir -p /mnt/etc/sudoers.d
tee /mnt/etc/sudoers.d/$NAME <<- EOF >> /dev/null
	$NAME ALL=(ALL) ALL
EOF

arch-chroot /mnt usermod -aG wheel $NAME

sleep 3

unset NAME

############################################################################
# TERMINATING

msg 2 "SETUP PROCESS COMPLETED"
sleep 2
