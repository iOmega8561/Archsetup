#!/usr/bin/env bash

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

function machine_checks {
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

function partition_checks {
    # We try to determine what is mounted
    # first on /mnt then on /mnt/boot

    declare temp="$(mount | grep " on /mnt ")"
    declare -gr PART_ROOT="${temp%%on /mnt*}"

    unset temp

    declare temp="$(mount | grep " on /mnt/boot ")"
    declare -gr PART_BOOT="${temp%%on /mnt/boot*}"

    # Here i may write some code to get UUIDs instead of volume names
    # for now we have names, good enough i guess
    # TO-BE-DONE
}

function bootloader_config {
    declare image="vmlinuz-$CFG_LINUX"

    # non-x86 systems might have their kernels named as "Image"
    # that is the case with arm64 machines
    if [ -f /mnt/boot/Image ] ; then
	    image="Image"
    fi

    # We'll write two entries, one for normal boot
    # the other for bootinf fallback initramfs

    tee /mnt/boot/loader/entries/02-arch-fallback.conf <<- EOF >> /dev/null
	    title "Arch Linux (fallback initramfs)"
	    linux /$image
	    initrd /initramfs-$CFG_LINUX-fallback.img
	    options root=$PART_ROOT rw
        sort-key arch-fallback
    EOF

    tee /mnt/boot/loader/entries/01-arch.conf <<- EOF >> /dev/null
	    title "Arch Linux"
	    linux /$image
	    initrd /initramfs-$CFG_LINUX.img
	    options root=$PART_ROOT rw
	    sort-key arch
    EOF

    # We want normal boot as default
    # 3 seconds timeout for the boot menu to appear

    tee /mnt/boot/loader/loader.conf <<- EOF >> /dev/null
	    default 01-arch
	    timeout 3
    EOF
}