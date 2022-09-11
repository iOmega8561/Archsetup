MSG="\e[33mARCHSCRIPT\e[0m:"

############################################################################
# CONF VARS

LANG="it_IT.UTF-8"
KEYMAP="it"
TIMEZONE="Europe/Rome"
LINUXOPT="nvidia-drm.modeset=1"

############################################################################
# INIT

echo "$MSG Please mount partitions first:"
echo "ROOT part to /mnt"
echo "BOOT part to /mnt/boot"
echo "HOME part to /mnt/home (if present)"
echo "$MSG PRESS ENTER TO INITIATE SETUP"
read

echo "$MSG Executing pacstrap to /mnt"

pacstrap /mnt base linux-zen linux-firmware amd-ucode base-devel sudo networkmanager nano python git
sleep 3

############################################################################
# FSTAB

echo "$MSG Generating fstab"
genfstab -U /mnt > /mnt/etc/fstab
sleep 3

############################################################################
# SYSTEMD-BOOT INSTALLATION

echo "$MSG Installing systemd-boot to /mnt/boot"
arch-chroot /mnt bootctl install
sleep 3

############################################################################
# SYSTEMD-BOOT CONFIGURATION

echo "$MSG Generating bootloader configuration"
tee /mnt/boot/loader/loader.conf <<- EOF >> /dev/null
	default normal
	timeout 3
	console-mode max
EOF
sleep 3

############################################################################
# SYSTEMD-BOOT ENTRIES

echo "$MSG Generating bootloader entries"

MOUNT=$(mount | grep " on /mnt type ext4 (rw,relatime)")
ROOT=${MOUNT%" on /mnt type ext4 (rw,relatime)"}

tee /mnt/boot/loader/entries/fallback.conf <<- EOF >> /dev/null
	title "Arch Linux (fallback initramfs)"
	linux /vmlinuz-linux-zen
	initrd /amd-ucode.img
	initrd /initramfs-linux-zen-fallback.img
	options root=$ROOT rw $LINUXOPT
EOF
tee /mnt/boot/loader/entries/normal.conf <<- EOF >> /dev/null
	title "Arch Linux"
	linux /vmlinuz-linux-zen
	initrd /amd-ucode.img
	initrd /initramfs-linux-zen.img
	options root=$ROOT rw $LINUXOPT
EOF
sleep 3

############################################################################
# LOCALES

echo "$MSG Setting up locale $LANG"

tee -a /mnt/etc/locale.gen <<- EOF >> /dev/null
	$LANG UTF-8
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
# USER CREATION

read -p "$MSG Enter a valid user name: " NAME
arch-chroot /mnt useradd $NAME -m

printf "$MSG Enter a valid password || "
arch-chroot /mnt passwd $NAME

mkdir -p /mnt/etc/sudoers.d
tee /mnt/etc/sudoers.d/$NAME <<- EOF >> /dev/null
	$NAME ALL=(ALL) ALL
EOF
sleep 3

############################################################################
# TIME AND TIMEZONE

echo "$MSG Setting timezone and system clock"

ln -sf /mnt/usr/share/zoneinfo/$TIMEZONE /etc/localtime
arch-chroot /mnt hwclock --systohc
sleep 3

############################################################################
# TERMINATING

echo "$MSG SETUP PROCESS COMPLETED"
sleep 2
