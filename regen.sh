#! /bin/bash

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

##------------------------------------------------------##
##----------Basic Informations, COMPULSORY--------------##

# The defult directory where the kernel should be placed
KERNEL_DIR=$PWD

# The codename of the device
DEVICE="X00TD"

# Define Build User
USER="ElectroPerf"

# The defconfig which should be used.
DEFCONFIG=asus/X00TD_defconfig

# Make savedefconfig
MAKE_SAVEDEFCONFIG=0

# Define Kernel Arch
KARCH=arm64

# Commit Your Changes
AUTO_COMMIT=0

# Silence Kbuild logging (msgs)
SILENCE=0

# Do not touch !
	msg "|| Cleaning Source ||"

	make clean mrproper distclean

	msg "|| Regenerating Defconfig ||"

	if [[ "$SILENCE" == "1" ]]; then
		FLAG='-s'
	fi
	
	COMPILER_STRING=$($KERNEL_DIR/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

	make O=out $DEFCONFIG $FLAG                       \
                   LLVM=1                                 \
   		   ARCH=$KARCH                            \
   	           KBUILD_BUILD_USER=$USER                \
   	           PATH=$KERNEL_DIR/clang/bin/:$PATH      \
                   CROSS_COMPILE=aarch64-linux-gnu-       \
                   CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
		   KBUILD_COMPILER_STRING=$COMPILER_STRING

	msg "|| Removing Old Defconfig ||"

	rm -rf arch/$KARCH/configs/$DEFCONFIG

	if [[ "$MAKE_SAVEDEFCONFIG" == "1" ]]; then
		msg "|| Making Savedefconfig ||"
		
		make O=out savedefconfig $FLAG
		
		msg "|| Moving Regenerated Defconfig ||"

		mv out/defconfig arch/$KARCH/configs/$DEFCONFIG	
	else
		msg "|| Moving Regenerated Defconfig ||"

		mv out/.config arch/$KARCH/configs/$DEFCONFIG	
	fi

	if [[ "$AUTO_COMMIT" == "1" ]]; then
		msg "|| Commiting Changes ||"

		git add arch/$KARCH/configs/$DEFCONFIG
		git commit -sSm "$DEFCONFIG: Regenerate"
	fi
