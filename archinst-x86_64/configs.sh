# Linux Kernel to install from linux, linux-zen, linux-lts, linux-hardened
export LINUX="linux-zen"

# CPU microcode, amd-ucode or intel-ucode
export UCODE="amd-ucode"

# System locale
export LANG="it_IT.UTF-8"

# System locale encoding
export ENCODING="UTF-8"

# vconsole keymap
export KEYMAP="it"

# System timezone
export TIMEZONE="Europe/Rome"

# System hostname
export HOSTNAME="newarch"

# Install or not Zram
export ZRAM=true

# Zram size, default is min(ram / 2, 4096)
export ZRAMSIZE="min(ram / 2, 4096)"
