#!/usr/bin/env bash
# Copyright (c) 2021-2023, Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>.
# Version: 10.1
# Revision: 29-06-2023
# shellcheck disable=SC2312
# shellcheck disable=SC1091
# shellcheck disable=SC2154

## Global variables
# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"

# User details
USER='Tashar'
HOST='Endeavour'
TOKEN='ADD YOUR TOKEN HERE'
CHATID='ADD YOUR CHATID HERE'
BOT_MSG_URL="https://api.telegram.org/bot${TOKEN}/sendMessage"
BOT_BUILD_URL="https://api.telegram.org/bot${TOKEN}/sendDocument"
DEVICE='Mi A2 / 6X'
CODENAME='wayne'
CODENAME2='jasmine'
PROCS="$(nproc --all)"

# Paths
KERNEL_DIR="${PWD}"
TOOLCHAIN="${KERNEL_DIR}/../toolchains"
GZIP_DIR="${TOOLCHAIN}/neutron-gzip"
COREUTILS_DIR="${TOOLCHAIN}/neutron-coreutils"
ZIP_DIR="${KERNEL_DIR}/../4.19-ak3"

## Go to kernel directory
cd "${KERNEL_DIR}" || exit 1

## Functions
# A function to showcase the help section of the script
help() {
	echo -e "${CYAN}
Usage ./kramel.sh [ARG]

Arguments:
 --clang		sets clang as the compiler
 --gcc			sets gcc as the compiler
 --newcam		sets newcam as the camera library
 --oldcam		sets oldcam as the camera library
 --osscam		sets osscam as the camera library
 --qpnp			sets qpnp as the haptics driver
 --qti			sets qti as the haptics driver
 --dynamic		sets retrofit dynamic partition
 --non-dynamic		sets regular partition type
 --thin-lto		enables thin LTO
 --full-lto		enables full LTO
 --non-lto		disables LTO
 --help			shows this menu
"
}

# A function to send message(s) via Telegram's BOT api
tg_post_msg() {
	curl -s -X POST "${BOT_MSG_URL}" \
		-d chat_id="${CHATID}" \
		-d "disable_web_page_preview=true" \
		-d "parse_mode=html" \
		-d text="$1"
}

# A function to send file(s) via Telegram's BOT api
tg_post_build() {
	#Post MD5Checksum alongwith for easeness
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	#Show the Checksum alongwith caption
	curl --progress-bar -F document=@"$1" "${BOT_BUILD_URL}" \
		-F chat_id="${CHATID}" \
		-F "disable_web_page_preview=true" \
		-F "parse_mode=html" \
		-F caption="$2 | <b>MD5 Checksum : </b><code>${MD5CHECK}</code>"
}

## Argument list
for args in "${@}"; do
	case "${args}" in
	"--clang")
		C_PATH="${TOOLCHAIN}/Neutron-Clang-BOLT"
		KBUILD_COMPILER_STRING="$(${C_PATH}/bin/clang -v 2>&1 | head -n 1 | sed 's/(https..*//' | sed 's/ version//')"
		MAKE+=(
			O=work
			CC='ccache clang'
			LLVM=1
			LLVM_IAS=1
			CROSS_COMPILE=aarch64-linux-gnu-
			CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
		)
		;;
	"--gcc")
		C_PATH="${TOOLCHAIN}/gcc64/bin:${TOOLCHAIN}/gcc32"
		KBUILD_COMPILER_STRING="$(${TOOLCHAIN}/gcc64/bin/aarch64-elf-gcc --version | head -n 1)"
		MAKE+=(
			O=work
			CC=aarch64-elf-gcc
			LD="${TOOLCHAIN}/gcc64/bin/aarch64-elf-ld.lld"
			LD_LIBRARY_PATH=${C_PATH}/lib:${LD_LIBRARY_PART}
			AR=llvm-ar
			NM=llvm-nm
			OBJCOPY=llvm-objcopy
			OBJDUMP=llvm-objdump
			OBJCOPY=llvm-objcopy
			OBJSIZE=llvm-size
			STRIP=llvm-strip
			CROSS_COMPILE=aarch64-elf-
			CROSS_COMPILE_COMPAT=arm-eabi-
			CC_COMPAT=arm-eabi-gcc
		)
		;;
	"--newcam")
		DFCF="vendor/${CODENAME}-perf_defconfig"
		CAM='NEWCAM'
		;;
	"--oldcam")
		DFCF="vendor/${CODENAME}-old-perf_defconfig"
		CAM='OLDCAM'
		;;
	"--osscam")
		DFCF="vendor/${CODENAME}-oss-perf_defconfig"
		CAM='OSSCAM'
		;;
	"--qpnp")
		HAPTIC='QPNP'
		;;
	"--qti")
		HAPTIC='QTI'
		;;
	"--dynamic")
		PARTITION='DYNAMIC'
		;;
	"--non-dynamic")
		PARTITION='NON-DYNAMIC'
		;;
	"--thin-lto")
		LTO_VARIANT='THIN_LTO'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -e 'CONFIG_LTO_CLANG_THIN'
		;&
	"--full-lto")
		LTO_VARIANT='FULL_LTO'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -d 'CONFIG_LTO_NONE'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -e 'CONFIG_LTO_CLANG_FULL'
		;;
	"--non-lto")
		LTO_VARIANT='NON_LTO'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -d 'CONFIG_LTO_CLANG_THIN'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -d 'CONFIG_LTO_CLANG_FULL'
		./scripts/config --file "${KERNEL_DIR}/arch/arm64/configs/${DFCF}" -e 'CONFIG_LTO_NONE'
		;;
	"--help")
		help
		exit 0
		;;
	*)
		echo -e "${YELLOW}Invaild argument(s) '${*}'. Run './kramel.sh --help'"
		sleep 1
		exit 1
		;;
	esac
done

## Export environment variables
export KBUILD_BUILD_USER="${USER}"
export KBUILD_BUILD_HOST="${HOST}"
export PATH="${COREUTILS_DIR}/bin:${GZIP_DIR}/bin:${C_PATH}/bin:${PATH}"
export ARCH='arm64'
export PYTHON='python3'

## Start compilation
rm -rf "${KERNEL_DIR}/work" "${KERNEL_DIR}/log.txt"
if [[ ! -d "${KERNEL_DIR}/out" ]]; then
	mkdir "${KERNEL_DIR}/out"
fi

BUILD_START="$(date +"%s")"
make -j"${PROCS}" "${DFCF}" "${MAKE[@]}"
echo -e "\n${CYAN}	Build started..."
echo -e "${GREEN}"
time make -j"${PROCS}" "${MAKE[@]}" 2>&1 | tee log.txt
git restore "${KERNEL_DIR}/arch/arm64/configs/${DFCF}"
echo -e "\n${CYAN}	Build finished. Zipping...\n"
BUILD_END="$(date +"%s")"
DIFF="$((BUILD_END - BUILD_START))"

## Start zipping and posting
if [[ -f "${KERNEL_DIR}/work/arch/arm64/boot/Image.gz-dtb" ]]; then
	tg_post_build "log.txt" "Compiled kernel successfully!!"
	source "${KERNEL_DIR}/work/.config"

	KNAME="$(echo "${CONFIG_LOCALVERSION}" | cut -c 2-)"
	KV="$(cat <"${KERNEL_DIR}/work/include/generated/utsrelease.h" | cut -c 21- | tr -d '"')"
	DATE="$(date +"%Y-%m-%d %H:%M")"
	COMMIT_NAME="$(git show -s --format=%s)"
	COMMIT_HASH="$(git rev-parse --short HEAD)"
	if [[ $PARTITION == NON-DYNAMIC ]]; then
		ZIP_NAME="${KNAME}-${CAM}-${HAPTIC}-${CODENAME2^^}-${CODENAME^^}-$(date +"%H%M")"
	else
		ZIP_NAME="${KNAME}-${CAM}-${HAPTIC}-${PARTITION}-${CODENAME2^^}-${CODENAME^^}-$(date +"%H%M")"
	fi
	FINAL_ZIP="${ZIP_NAME}-signed.zip"

	cp "${KERNEL_DIR}/work/arch/arm64/boot/Image.gz-dtb" "${ZIP_DIR}"
	cd "${ZIP_DIR}" || exit 1
	zip -r9 "${ZIP_NAME}.zip" * -x README.md LICENSE FUNDING.yml zipsigner*
	java -jar zipsigner* "${ZIP_NAME}.zip" "${FINAL_ZIP}"
	echo -e "\n${CYAN}	Pushing kernel zip...\n"
	if [[ $PARTITION == NON-DYNAMIC ]]; then
		tg_post_build "${FINAL_ZIP}" "${CAM}+${HAPTIC}"
	else
		tg_post_build "${FINAL_ZIP}" "${CAM}+${HAPTIC}+${PARTITION}"
	fi
	cp "${FINAL_ZIP}" "${KERNEL_DIR}/out"
	rm -rf *.zip Image.gz-dtb
	cd ${KERNEL_DIR}

	# Print the build information
	tg_post_msg "
	=========Scarlet-X Kernel=========
	Compiler: <code>${KBUILD_COMPILER_STRING}</code>
	Linux Version: <code>${KV}</code>
	Maintainer: <code>${USER}</code>
	Device: <code>${DEVICE}</code>
	Codename: <code>${CODENAME}</code>
	Zipname: <code>${FINAL_ZIP}</code>
	LTO Variant: <code>${LTO_VARIANT}</code>
	Build Date: <code>${DATE}</code>
	Build Duration: <code>$((DIFF / 60)).$((DIFF % 60)) mins</code>
	Last Commit Name: <code>${COMMIT_NAME}</code>
	Last Commit Hash: <code>${COMMIT_HASH}</code>
	"
else
	tg_post_build "log.txt" "Build failed!!"
	echo -e "\n${RED}	Kernel image not found"
	exit 1
fi
