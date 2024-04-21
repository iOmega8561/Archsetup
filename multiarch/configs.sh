# Linux Kernel to install from linux, linux-zen, linux-lts, linux-hardened
# This has no effect if cpu architecture is not x86_64, it will default to "linux"
export CFG_LINUX="linux-zen"

# System locale
export CFG_LANG="it_IT.UTF-8"

# System locale encoding
export CFG_ENCODING="UTF-8"

# vconsole keymap
export CFG_KEYMAP="it"

# System timezone
export CFG_TIMEZONE="Europe/Rome"

# System hostname
export CFG_HOSTNAME="newarch"

# Install or not Zram
export CFG_ZRAM=true

# Zram size, default is min(ram / 2, 4096)
export CFG_ZRAMSIZE="min(ram / 2, 4096)"
