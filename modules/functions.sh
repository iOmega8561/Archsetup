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


# In this file we store those routines that are not
# interactive and have a bunch of lines that may clog
# the main script too much and destroy readability
function log {

	declare code="0m"

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

function check_machine {
	declare -gr CPU_ARCH=$(uname --machine)

	# We always like to know the hardware we're dealing with
	declare temp="$(cat /proc/cpuinfo \
				  | grep --max-count=1 vendor_id)"
	
	declare -gr CPU_VENDOR="${temp##vendor_id*: }"

	# We do this check to skip unneeded microcode updates on Virtual Machines
	# non-x86 systems might not have any kernel flavour other than mainline
	# (for instance that is the case with arm64) so we just override CFG_LINUX
	if [[ "$CPU_ARCH" != "x86_64" ]] || \
	   [[ -n $(dmesg | grep Hyper) ]]
	then
		unset CFG_LINUX
		declare -gr CFG_LINUX=linux

		return
	fi

	# Here we know that this is not a VM and is a x86 machine,
	# Let's figure out what microcode we should install
	case $CPU_VENDOR in
		AuthenticAMD)
			declare -gr CPU_UCODE="amd-ucode"
			;;
		GenuineIntel)
			declare -gr CPU_UCODE="intel-ucode"
			;;
		*)
			;;
	esac
}

function check_mounts {
	# We try to determine what is mounted
	# first on /mnt then on /mnt/boot

	declare temp="$(mount | grep " on /mnt ")"
	declare -gr PART_ROOT="${temp%%on /mnt*}"

	unset temp

	declare temp="$(mount | grep " on /mnt/boot ")"
	declare -gr PART_BOOT="${temp%%on /mnt/boot*}"

	# If either of these two is zero, something is
	# not mounted correctly, so we return 1
	if [[ -z $PART_ROOT ]] ||\
	   [[ -z $PART_BOOT ]]
	then
		return 1
	fi

	# Here i may write some code to get UUIDs instead of volume names
	# for now we have names, good enough i guess
	# TO-BE-DONE
}

function config_bootloader {
	# This function wants the Linux Kernel flavour
	# and the root partition name/UUID as input parameters
	declare linux="$1"
	declare root="$2"

	# non-x86 systems might have their kernels named as "Image"
	# that is the case with arm64 machines
	declare image="vmlinuz-$linux"

	if [ -f /mnt/boot/Image ] ; then
		image="Image"
	fi

	# We'll write two entries, one for normal boot
	# the other for bootinf fallback initramfs

	tee /mnt/boot/loader/entries/02-arch-fallback.conf <<- EOF >> /dev/null
		title "Arch Linux (fallback initramfs)"
		linux /$image
		initrd /initramfs-$linux-fallback.img
		options root=$root rw
		sort-key 02-arch-fallback
	EOF

	tee /mnt/boot/loader/entries/01-arch.conf <<- EOF >> /dev/null
		title "Arch Linux"
		linux /$image
		initrd /initramfs-$linux.img
		options root=$root rw
		sort-key 01-arch
	EOF

	# We want normal boot as default
	# 3 seconds timeout for the boot menu to appear

	tee /mnt/boot/loader/loader.conf <<- EOF >> /dev/null
		default 01-arch
		timeout 3
	EOF
}

function config_localization {
	# This function wants these three parameters
	# LANG can be any value in /etc/locale.gen
	# ENCODING can be any encoding value in /etc/locale.gen
	# KEYMAP can be any value displayed by "localectl list-keymaps"
	# in this order

	declare lang="$1"
	declare encoding="$2"
	declare keymap="$3"

	tee -a /mnt/etc/locale.gen <<- EOF >> /dev/null
		$lang $encoding
	EOF

	tee /mnt/etc/locale.conf <<- EOF >> /dev/null
		LANG=$lang
	EOF

	tee /mnt/etc/vconsole.conf <<- EOF >> /dev/null
		KEYMAP=$keymap
	EOF

	arch-chroot /mnt locale-gen
}

function config_localtime {
	# This function wants a TIMEZONE parameter
	# (Country/City format)

	declare tz="$1"

	arch-chroot /mnt ln --symbolic --force \
					 /usr/share/zoneinfo/$tz \
					 /etc/localtime

	arch-chroot /mnt hwclock --systohc
}

function config_zram {
	# This function wants ZRAMSIZE as input parameter
	# Could be any value accepted by zram-generator.conf
	# https://wiki.archlinux.org/title/Zram#Using_zram-generator

	arch-chroot /mnt pacman -S --noconfirm \
					 zram-generator
	
	tee /mnt/etc/systemd/zram-generator.conf <<- EOF >> /dev/null
		[zram0]
		zram-size = $CFG_ZRAMSIZE
	EOF
}