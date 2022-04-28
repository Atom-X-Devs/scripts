#!/bin/bash

#########################    CONFIGURATION    ##############################

# User details
KBUILD_USER="$USER"
KBUILD_HOST=$(uname -n)

# Build type (Fresh build: clean | incremental build: dirty)
# (default: dirty | modes: clean, dirty)
BUILD='clean'

############################################################################

########################   DIRECTORY PATHS   ###############################

# Propriatary Directory (default paths may not work!)
PRO_PATH="$HOME/Desktop/Atom-X-Projekt"

# Kernel Directory
KERNEL_DIR=`pwd`

# Anykernel Directories
AK3_DIR="$PRO_PATH/AnyKernel3"
AKSH="$AK3_DIR/anykernel.sh"
AKVDR="$AK3_DIR/modules/vendor/lib/modules"

# Toolchain Directory
TLDR="$PRO_PATH/toolchains"

# Device Tree Blob Directory
DTB_PATH="$KERNEL_DIR/work/arch/arm64/boot/dts/vendor/qcom"

############################################################################

###############################   COLORS   #################################

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
W='\033[1;37m'

############################################################################

################################   MISC   ##################################

# functions
error() {
	echo -e ""
	echo -e "$R ${FUNCNAME[0]}: $W$@"
	echo -e ""
	exit 1
}

success() {
	echo -e ""
	echo -e "$G ${FUNCNAME[1]}: $W$@"
	echo -e ""
	exit 0
}

inform() {
	echo -e ""
	echo -e "$B ${FUNCNAME[1]}: $W$@$G"
	echo -e ""
}

muke() {
	if [[ "$SILENCE" == "1" ]]; then
		KERN_MAKE_ARGS="-s $KERN_MAKE_ARGS"
	fi

	make $@ $KERN_MAKE_ARGS
}

usage() {
	inform " ./AtomX.sh <arg>
		--compiler   sets the compiler to be used
		--device     sets the device for kernel build
		--dtbs       Builds dtbs, dtbo & dtbo.img
		--regen      Regenerates defconfig (makes savedefconfig)
		--generate_defconfig  Generates defconfig (Used for qgki/gki config fragements)
		--silence    Silence shell output of Kbuild"
	exit 2
}

############################################################################

compiler_setup() {
############################  COMPILER SETUP  ##############################
	case $COMPILER in
		clang)
			CC='clang'
			C_PATH="$TLDR/neutron-clang"
		;;
		gcc)
			CC='aarch64-elf-gcc'
			KERN_MAKE_ARGS="                     \
					HOSTCC=gcc                   \
					CC=$CC                       \
					HOSTCXX=aarch64-elf-g++      \
					CROSS_COMPILE=aarch64-elf-"
			C_PATH="$TLDR/gcc-arm64"
		;;
	esac
	CC_32="$TLDR/gcc-arm/bin/arm-eabi-"
	CC_COMPAT="$TLDR/gcc-arm/bin/arm-eabi-gcc"

	KERN_MAKE_ARGS="$KERN_MAKE_ARGS      \
		ARCH=arm64                       \
		O=work                           \
		LLVM=1                           \
		LLVM_IAS=1                       \
		HOSTLD=ld.lld                    \
		CC_COMPAT=$CC_COMPAT             \
		PATH=$C_PATH/bin:$PATH           \
		CROSS_COMPILE_COMPAT=$CC_32      \
		KBUILD_BUILD_USER=$KBUILD_USER   \
		KBUILD_BUILD_HOST=$KBUILD_HOST   \
		LD_LIBRARY_PATH=$C_PATH/lib:$LD_LIBRARY_PATH"
############################################################################
}

compile_config_generator() {
#########################  .config GENERATOR  ############################
	if [[ -z $CODENAME ]]; then
		error 'Codename not present connot proceed'
		exit 1
	fi

	inform "Genertating .config"

	DFCF="vendor/${CODENAME}-${SUFFIX}_defconfig"

	# Make .config
	muke $DFCF
############################################################################
}

defconfig_generator() {
#########################  DEFCONFIG GENERATOR  ############################
	if [[ "$GENERATE_DEFCONFIG" == "1" ]]; then
		export $KERN_MAKE_ARGS TARGET_BUILD_VARIANT=user

		bash scripts/gki/generate_defconfig.sh "${CODENAME}-${SUFFIX}_defconfig"
	fi
############################################################################
}

defconfig_regenerator() {
########################  DEFCONFIG REGENERATOR  ###########################
	compile_config_generator

	inform "Regenertating defconfig"

	muke savedefconfig

	cat work/defconfig > arch/arm64/configs/$DFCF

	success "Regenertation completed"
############################################################################
}

dtb_builder() {
##########################   DTBO BUILDER   #################################
	compile_config_generator

	inform "Building dtbs"

	muke dtbs

	success "Building dtbs completed"
############################################################################
}

kernel_builder() {
##################################  BUILD  #################################
	case $BUILD in
		clean)
			rm -rf work || mkdir work
		;;
		*)
			muke clean mrproper distclean
		;;
	esac

	compile_config_generator

	# Build Start
	BUILD_START=$(date +"%s")

	inform "
	*************Build Triggered*************
	Date: $(date +"%Y-%m-%d %H:%M")
	Build Type: $BUILD_TYPE
	Device: $DEVICENAME
	Codename: $CODENAME
	Compiler: $($C_PATH/bin/$CC --version | head -n 1 | perl -pe 's/\(http.*?\)//gs')
	Compiler_32: $($CC_COMPAT --version | head -n 1)
	"

	# Compile
	muke -j$(nproc) drivers/input/fingerprint/

	if [[ "$MODULES" == "1" ]]; then
		muke -j$(nproc)          \
			'modules_install'    \
			INSTALL_MOD_STRIP=1  \
			INSTALL_MOD_PATH="modules"
	fi

	# Build End
	BUILD_END=$(date +"%s")

	DIFF=$(($BUILD_END - $BUILD_START))

	if [[ -f $KERNEL_DIR/work/arch/arm64/boot/$TARGET ]]; then
		zipper
	else
		error 'Kernel image not found'
	fi
############################################################################
}

zipper() {
####################################  ZIP  #################################
	source work/.config

	if [[ ! -d $AK3_DIR ]]; then
		error 'Anykernel not present cannot zip'
	fi
	if [[ ! -d "$KERNEL_DIR/out" ]]; then
		mkdir $KERNEL_DIR/out
	fi

	cp $KERNEL_DIR/work/arch/arm64/boot/$TARGET $AK3_DIR
	cp $DTB_PATH/*.dtb $AK3_DIR/dtb
	cp $DTB_PATH/*.img $AK3_DIR/
	if [[ "$MODULES" == "1" ]]; then
		MOD_NAME="$(cat work/include/generated/utsrelease.h | cut -c 21- | tr -d '"')"
		MOD_PATH="work/modules/lib/modules/$MOD_NAME"

		cp $(find $MOD_PATH -name '*.ko') $AKVDR
		cp $MOD_PATH/modules.{alias,dep,softdep} $AKVDR
		cp $MOD_PATH/modules.order $AKVDR/modules.load
		sed -i 's/\(kernel\/[^: ]*\/\)\([^: ]*\.ko\)/\/vendor\/lib\/modules\/\2/g' $AKVDR/modules.dep
		sed -i 's/.*\///g' $AKVDR/modules.load
	fi

	cd $AK3_DIR

	make zip VERSION=`echo $CONFIG_LOCALVERSION | cut -c 8-`

	KERNEL_VERSION=$(make kernelversion)
	LAST_COMMIT=$(git show -s --format=%s)
	LAST_HASH=$(git rev-parse --short HEAD)

	inform "
	*************AtomX-Kernel*************
	Linux Version: $KERNEL_VERSION
	CI: $KBUILD_HOST
	Core count: $(nproc)
	Compiler: $($C_PATH/bin/$CC --version | head -n 1)
	Compiler_32: $($CC_COMPAT --version | head -n 1)
	Device: $DEVICENAME
	Codename: $CODENAME
	Build Date: $(date +"%Y-%m-%d %H:%M")
	Build Type: $BUILD_TYPE

	-----------last commit details-----------
	Last commit (name): $LAST_COMMIT

	Last commit (hash): $LAST_HASH
	"

	cp *-signed.zip $KERNEL_DIR/out

	make clean

	cd $KERNEL_DIR

	success "build completed in $(($DIFF / 60)).$(($DIFF % 60)) mins"

############################################################################
}

###############################  COMMAND_MODE  ##############################
if [[ -z $* ]]; then
	usage
fi

for arg in "$@"; do
	case "${arg}" in
		"--compiler="*)
			COMPILER=${arg#*=}
			case ${COMPILER} in
				clang)
					COMPILER="clang"
				;;
				gcc)
					COMPILER="gcc"
				;;
				*)
					usage
				;;
			esac
			compiler_setup
		;;
		"--device="*)
			CODE_NAME=${arg#*=}
			case $CODE_NAME in
				lisa)
					DEVICENAME='Xiaomi 11 lite 5G NE'
					CODENAME='lisa'
					SUFFIX='qgki'
					MODULES='1'
					TARGET='Image'
				;;
				lisa-no-mod)
					DEVICENAME='Xiaomi 11 lite 5G NE'
					CODENAME='lisa'
					SUFFIX='qgki'
					TARGET='Image'
				;;
				*)
					error 'device not supported'
				;;
			esac
		;;
		"--dtbs")
			dtb_builder
		;;
		"--regen")
			defconfig_regenerator
		;;
		"--generate_defconfig")
			GENERATE_DEFCONFIG='1'
		;;
		"--silence")
			SILENCE='1'
		;;
		*)
			usage
		;;
	esac
done
############################################################################

defconfig_generator
kernel_builder