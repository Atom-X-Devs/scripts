#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2022-2023, Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>.
# Revision: 11-01-2023 V3.3

## Global variables and arrays
# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"

# Compiler's path
C_PATH="$(pwd)/clang"

# Array to regenerate defconfigs in a loop
# Add or remove device names based on your needs
DEVICE=('whyred' 'tulip' 'wayne' 'wayne-old' 'wayne-oss' 'lavender')

# Check availability of device name(s)
if [[ ! ${DEVICE[*]} ]]; then
	echo -e "\n${RED}Error! Device name is not pre-defined"
	exit 1
fi

## Functions
# Create a box for the prompt screen
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

## Create build environment
# Prompt screen with the box style menu
echo -e "\n$GREEN	Regeneration Method"
box_out '1. Regenerate full defconfigs' \
	'2. Regenerate with Savedefconfig' \
	'e. EXIT'

read -p "$(echo -e "${CYAN}Enter your choice or press 'e' to go back to shell: ")" -r selector

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
	echo -e "\n${CYAN}Exiting..."
	sleep 1
	exit 0
	;;
*)
	echo -e "\n${RED}Error! Invalid option chosen"
	sleep 1
	exit 1
	;;
esac

# Clone clang if not available
if [[ ! -d $C_PATH ]]; then
	echo -e "\n${YELLOW}Clang not found! Cloning Neutron-clang..."
	mkdir "$C_PATH" && cd "$C_PATH" || exit
	bash <(curl -s https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman) -S
	cd - || exit
fi

# Export necessary build variables
export PATH="$C_PATH/bin/:$PATH"
export ARCH='arm64'
export LLVM=1
export LLVM_IAS=1

## Start regeneration of defconfigs
for prefix in "${DEVICE[@]}"; do
	# Variables for defconfig name and path
	DFCF="vendor/${prefix}-perf_defconfig"
	DFCF_PATH="arch/arm64/configs/$DFCF"

	# Begin regeneration...
	# Do not double quote $SAVE_DFCF as it will become an
	# empty string if option 1 is chosen at the selector
	make O=regen "$DFCF" $SAVE_DFCF
	mv regen/"$CONFIG" "$DFCF_PATH"
	rm -rf regen
	git add "$DFCF_PATH"
	echo -e ''
done

# Commit changes
git commit -sm "$COMMIT_MSG"
