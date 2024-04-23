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


# In this file we store all the config constants we need.
# The values below need to be customized according to user needs

# Linux Kernel to install from linux, linux-zen, linux-lts, linux-hardened
# This has no effect if cpu architecture is not x86_64, it will default to "linux"
# Actually this is not a constant, because it may need to be overidden later
declare -g CFG_LINUX="linux"

# System locale
# Possible values can be checked in /etc/locale.gen
declare -gr CFG_LANG="it_IT.UTF-8"

# System locale encoding
# Possible values can be checked in /etc/locale.gen
declare -gr CFG_ENCODING="UTF-8"

# vconsole keymap
# Possible values can be checked with "localectl list-keymaps"
declare -gr CFG_KEYMAP="it"

# System timezone
declare -gr CFG_TIMEZONE="Europe/Rome"

# System hostname
declare -gr CFG_HOSTNAME="newarch"

# Install or not Zram
declare -gr CFG_ZRAM=true

# Zram size, default is min(ram / 2, 4096)
declare -gr CFG_ZRAMSIZE="min(ram / 2, 4096)"
