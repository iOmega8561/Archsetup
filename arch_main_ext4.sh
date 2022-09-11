echo "Please mount partitions first:"
echo "ROOT part to /mnt"
echo "BOOT part to /mnt/boot"
echo "HOME part to /mnt/home"
echo "PRESS ENTER TO INITIATE SETUP"
read

############################################################################
# PACSTRAP

pacstrap /mnt base linux-zen linux-firmware amd-ucode base-devel sudo networkmanager nano python git
sleep 3

############################################################################
# FSTAB

echo "Generating fstab"
genfstab -U /mnt > /mnt/etc/fstab
sleep 3

############################################################################
# SYSTEMD-BOOT INSTALLATION

echo "Installing systemd-boot to /mnt/boot"
arch-chroot /mnt bootctl-install
sleep 3

############################################################################
# SYSTEMD-BOOT CONFIGURATION

echo "Generating bootloader configuration"
tee /mnt/boot/loader/loader.conf <<- EOF >> /dev/null
	default normal
	timeout 3
	console-mode max
EOF
sleep 3

############################################################################
# SYSTEMD-BOOT ENTRIES

echo "Generating bootloader entries"

STR=$(mount | grep " on /mnt type ext4 (rw,relatime)")
ROOT=${STR%" on /mnt type ext4 (rw,relatime)"}

tee /mnt/boot/loader/entries/fallback.conf <<- EOF >> /dev/null
	title "Arch Linux (fallback initramfs)"
	linux /vmlinuz-linux-zen
	initrd /amd-ucode.img
	initrd /initramfs-linux-zen-fallback.img
	options root=$ROOT rw nvidia-drm.modeset=1
EOF
tee /mnt/boot/loader/entries/normal.conf <<- EOF >> /dev/null
	title "Arch Linux"
	linux /vmlinuz-linux-zen
	initrd /amd-ucode.img
	initrd /initramfs-linux-zen.img
	options root=$ROOT rw nvidia-drm.modeset=1
EOF
sleep 3

############################################################################
# LOCALES

echo "Setting up locales for it_IT.UTF-8"

tee -a /mnt/etc/locale.gen <<- EOF >> /dev/null
	it_IT.UTF-8 UTF-8
EOF

tee /mnt/etc/locale.conf <<- EOF >> /dev/null
	LANG=it_IT.UTF-8
EOF

tee /mnt/etc/vconsole.conf <<- EOF >> /dev/null
	KEYMAP=it
EOF

arch-chroot /mnt locale-gen
sleep 3

############################################################################
# USER CREATION

read -p "Enter a valid user name: " NAME
arch-chroot /mnt useradd $NAME -m

printf "Enter a valid password"
arch-chroot /mnt passwd $NAME

mkdir -p /mnt/etc/sudoers.d
tee /mnt/etc/sudoers.d/$NAME <<- EOF >> /dev/null
	$NAME ALL=(ALL) ALL
EOF
sleep 3

############################################################################
# TIME AND TIMEZONE

ln -sf /mnt/usr/share/zoneinfo/Europe/Rome /etc/localtime
arch-chroot /mnt hwclock --systohc
sleep 3

############################################################################
# TERMINATING

echo "SETUP PROCESS COMPLETED"
sleep 2
