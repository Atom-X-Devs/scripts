#!/usr/bin/env bash

 # Script For Regenerating Defconfig of Android arm64 Kernel
 #
 # Copyright (c) 2021 ElectroPerf <kunmun.devroms@gmail.com>
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #      http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #

# Function to show an informational message
msg() {
    echo -e "\e[1;32m$*\e[0m"
}

err() {
    echo -e "\e[1;41m$*\e[0m"
}

##------------------------------------------------------##
##----------Basic Informations, COMPULSORY--------------##

# The defult directory where the kernel should be placed
KERNEL_DIR=$PWD

# The name of the device for which the kernel is built
MODEL="Asus Zenfone Max Pro M1"

# The codename of the device
DEVICE="X00TD"

# The defconfig which should be used. Get it from config.gz from
# your device or check source
DEFCONFIG=asus/X00TD_defconfig

# Show manufacturer info
MANUFACTURERINFO="ASUSTek Computer Inc."

# Clone Toolchain
git clone --depth=1 git@gitlab.com:ElectroPerf/atom-x-clang.git clang

# Define Kernel Arch
KARCH=arm64

# Commit Your Changes
AUTO_COMMIT=0

	msg "|| Export Kernel Arch ||"

	export ARCH=$KARCH

	msg "|| Cleaning Sources ||"

	make clean && make mrproper

	msg "|| Regenerating Defconfig ||"

		export KBUILD_BUILD_USER="Kunmun@Atom-X-Devs"
		TC_DIR=$KERNEL_DIR/clang
		KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
		PATH=$TC_DIR/bin/:$PATH

	export PATH KBUILD_COMPILER_STRING
	PROCS=$(nproc --all)
	export PROCS

	msg "|| Make Defconfig ||"
	make O=out $DEFCONFIG \
			CROSS_COMPILE=aarch64-linux-gnu- \
			CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
			CC=clang \
			LLVM=1 \
			LLVM_IAS=1 \
			LD="ld.lld" \
			LD_LIBRARY_PATH=$TC_DIR/lib

	msg "|| Moving Regenerated Defconfig ||"

	cp -af out/.config arch/$KARCH/configs/$DEFCONFIG

	if [ $AUTO_COMMIT = 1 ]
	then
		msg "|| Commiting Changes ||"

		git add arch/$KARCH/configs/$DEFCONFIG
		git commit -m "$DEFCONFIG: Regenerate" --signoff

	fi
