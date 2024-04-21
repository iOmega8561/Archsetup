# Linux Kernel to install from linux, linux-zen, linux-lts, linux-hardened
# This has no effect if cpu architecture is not x86_64, it will default to "linux"
declare -g CFG_LINUX="linux"

# System locale
declare -gr CFG_LANG="it_IT.UTF-8"

# System locale encoding
declare -gr CFG_ENCODING="UTF-8"

# vconsole keymap
declare -gr CFG_KEYMAP="it"

# System timezone
declare -gr CFG_TIMEZONE="Europe/Rome"

# System hostname
declare -gr CFG_HOSTNAME="newarch"

# Install or not Zram
declare -gr CFG_ZRAM=true

# Zram size, default is min(ram / 2, 4096)
declare -gr CFG_ZRAMSIZE="min(ram / 2, 4096)"
