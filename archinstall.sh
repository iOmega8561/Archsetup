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

MSG="\033[0;33mSETUP\033[0m:"
############################################################################
# INIT

echo -e "$MSG CHECK CONFIGURATION"
echo "SETTINGS         VALUES"
echo "Kernel:          $LINUX"
echo "Microcode:       $UCODE"
echo "Locale:          $LANG $ENCODING"
echo "Keymap:          $KEYMAP"
echo "Timezone:        $TIMEZONE"
echo "Zram size:       $ZRAMSIZE"
echo -e "$MSG PRESS ENTER TO CONFIRM"
read

echo -e "$MSG ENSURE PARTITIONS ARE MOUNTED:"
echo "ROOT partition to /mnt (NO LUKS NO LVM)"
echo "BOOT part to /mnt/boot (MUST BE EFI TYPE-UUID)"
echo "HOME part to /mnt/home (if present)"
echo -e "$MSG PRESS ENTER TO CONFIRM AND START"
read

echo -e "$MSG EXECUTING PACSTRAP TO /mnt"

pacstrap /mnt base $LINUX linux-firmware $UCODE base-devel sudo zram-generator networkmanager nano
sleep 3

############################################################################
# FSTAB

echo -e "$MSG GENERATING FSTAB"
genfstab -U /mnt > /mnt/etc/fstab
sleep 3

############################################################################
# SYSTEMD-BOOT INSTALLATION

echo -e "$MSG INSTALLING SYSTEMD-BOOT"
arch-chroot /mnt bootctl install
sleep 3

############################################################################
# SYSTEMD-BOOT CONFIGURATION

echo -e "$MSG WRITING BOOTLOADER CONFIGURATION"
tee /mnt/boot/loader/loader.conf <<- EOF >> /dev/null
	default normal
	timeout 3
EOF
sleep 3

############################################################################
# SYSTEMD-BOOT ENTRIES

echo -e "$MSG WRITING BOOTLOADER ENTRIES"

MOUNT=$(mount | grep " on /mnt ")
ROOT="${MOUNT%%on /*}"

tee /mnt/boot/loader/entries/fallback.conf <<- EOF >> /dev/null
	title "Arch Linux (fallback initramfs)"
	linux /vmlinuz-$LINUX
	initrd /$UCODE.img
	initrd /initramfs-$LINUX-fallback.img
	options root=$ROOT rw $BOOTARGS
EOF

tee /mnt/boot/loader/entries/normal.conf <<- EOF >> /dev/null
	title "Arch Linux"
	linux /vmlinuz-$LINUX
	initrd /$UCODE.img
	initrd /initramfs-$LINUX.img
	options root=$ROOT rw $BOOTARGS
EOF
sleep 3

############################################################################
# LOCALES

echo -e "$MSG SETTING LOCALE $LANG"

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

echo -e "$MSG SETTING SYSTEM TIME"

ln -sf /mnt/usr/share/zoneinfo/$TIMEZONE /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc
sleep 3

############################################################################
# ZRAM

echo -e "$MSG SETTING ZRAM SIZE"

tee /etc/systemd/zram-generator.conf <<- EOF >> /dev/null
	[zram0]
	zram-size = $ZRAMSIZE
EOF

############################################################################
# USER CREATION

echo -e "$MSG ENTER A VALID USERNAME: "
read NAME
arch-chroot /mnt useradd $NAME -m

echo -e "$MSG ENTER A VALID PASSWORD"
arch-chroot /mnt passwd $NAME

mkdir -p /mnt/etc/sudoers.d
tee /mnt/etc/sudoers.d/$NAME <<- EOF >> /dev/null
	$NAME ALL=(ALL) ALL
EOF
sleep 3

############################################################################
# TERMINATING

echo -e "$MSG SETUP PROCESS COMPLETED"
sleep 2
