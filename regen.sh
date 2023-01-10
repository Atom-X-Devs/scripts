#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2022-2023, Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>.
# Revision: 11-01-2023 V3.3

# Variables for colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"

# Function to create a box for the prompt screen
# Source: https://unix.stackexchange.com/a/70616
box_out() {
	local s=("$@") b w
	for l in "${s[@]}"; do
		((w < ${#l})) && { b="$l"; w="${#l}"; }
	done
	tput setaf 3
	echo " -${b//?/-}-
| ${b//?/ } |"
	for l in "${s[@]}"; do
		printf '| %s%*s%s |\n' "$(tput setaf 4)" "-$w" "$l" "$(tput setaf 3)"
	done
	echo "| ${b//?/ } |
 -${b//?/-}-"
	tput sgr 0
}

# Prompt screen
echo -e "\n$GREEN Regen Method"
box_out '1. Regenerate full defconfigs' \
	'2. Regenerate with Savedefconfig' \
	'e. EXIT'
echo -ne "\n$CYAN Enter your choice or press 'e' to go back to shell: "

read -r selector

# Variables for different defconfig regeneration types
case $selector in
1)
	CONFIG='.config'
	COMMIT_MSG='defconfigs: xiaomi: Regenerate Defconfigs'
	;;
2)
	SAVE_DFCF='savedefconfig'
	CONFIG='defconfig'
	COMMIT_MSG='defconfigs: xiaomi: Regenerate with Savedefconfig'
	;;
e)
	echo -e "\n$CYAN Exiting..."
	sleep 1
	exit 0
	;;
esac

# Bail out with an error message if invalid option is chosen
if [[ "$selector" != "1" && "$selector" != "2" ]]; then
	echo -e "\n$RED Error! Invalid option chosen!"
	exit 1
fi

# Clone clang if not available
if test ! -d 'neutron-clang'; then
	echo -e "\n$YELLOW Clang not found! Cloning Neutron-clang..."
	mkdir neutron-clang && cd neutron-clang
	bash <(curl -s https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman) -S
	cd -
fi

# Export necessary build variables
export PATH="$(pwd)/neutron-clang/bin/:$PATH"
export ARCH='arm64'
export LLVM=1
export LLVM_IAS=1

# Array to regenerate defconfigs in a loop
# Add or remove device names based on your needs
DEVICE+=('whyred' 'tulip' 'wayne' 'wayne-old' 'wayne-oss' 'lavender')

# Start regeneration of defconfigs
for prefix in "${DEVICE[@]}"; do
	# Define the device name prefixes
	echo "$prefix"

	# Variables for defconfig name and path
	DFCF="vendor/${prefix}-perf_defconfig"
	DFCF_PATH="arch/arm64/configs/$DFCF"

	# Begin regeneration...
	# Do not quote $SAVE_DFCF as it will become an
	# empty string if option 1 is chosen at the selector
	make O=regen "$DFCF" $SAVE_DFCF
	mv regen/"$CONFIG" "$DFCF_PATH"
	rm -rf regen
	git add "$DFCF_PATH"
	echo -e ''
done

# Commit changes
git commit -asm "$COMMIT_MSG"
