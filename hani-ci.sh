#!/bin/bash
#
# Compile script for hanikrnl.
# Copyright (C)2022 Ardany Jolón
SECONDS=0 # builtin bash timer
KERNEL_PATH=$PWD
TC_DIR="$HOME/tc/clang-14.0.0"
GCC_64_DIR="$HOME/tc/aarch64-linux-android-4.9"
GCC_32_DIR="$HOME/tc/arm-linux-androideabi-4.9"
AK3_DIR="$HOME/tc/AnyKernel3"
DEFCONFIG="vendor/chime_defconfig"
export KBUILD_BUILD_USER=hani
export KBUILD_BUILD_HOST=dungeon
export PATH="$TC_DIR/bin:$PATH"

# Install needed tools
if [[ $1 = "-t" || $1 = "--tools" ]]; then
        git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 $HOME/tc/aarch64-linux-android-4.9
        git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 $HOME/tc/arm-linux-androideabi-4.9
        wget https://gitlab.com/itsHanibee/clang/-/archive/14.0.0/clang-14.0.0.tar.gz -O $HOME/tc/clang-14.0.0.tar.gz && tar xvf $HOME/tc/clang-14.0.0.tar.gz -C $HOME/tc/
        touch $HOME/tc/clang-12.0.0/AndroidVersion.txt && echo -e "14.0.0" | sudo tee -a $HOME/tc/clang-14.0.0/AndroidVersion.txt > /dev/null 2>&1
fi

# Regenerate defconfig file
if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
fi

# Make a clean build
if [[ $1 = "-c" || $1 = "--clean" ]]; then
	rm -rf out
fi

if [[ $1 = "-b" || $1 = "--build" ]]; then
	export ARCH=arm64
	mkdir -p out
	make O=out CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 $DEFCONFIG
	echo -e ""
	echo -e ""
	echo -e "*****************************"
	echo -e "**                         **"
	echo -e "** Starting compilation... **"
	echo -e "**                         **"
	echo -e "*****************************"
	echo -e ""
	echo -e ""
        threads=$(nproc --all)
        echo -e $threads
	make O=out -j$(( 2 * $(nproc --all))) O=out ARCH=arm64 CC=clang LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-android- CROSS_COMPILE_ARM32=$GCC_32_DIR/bin/arm-linux-androideabi- CLANG_TRIPLE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 || exit 69

	kernel="out/arch/arm64/boot/Image"
	dtbo="out/arch/arm64/boot/dtbo.img"
	dtb="out/arch/arm64/boot/dtb.img"

	if [ -f "$kernel" ]; then
		rm *.zip 2>/dev/null
		# Set kernel name and version
		hash=$(git log -n 1 --pretty=format:'%h')
		lastcommit=$hash
		REVISION=4.19-hanikrnl.$lastcommit
		ZIPNAME=""$REVISION"-beehive-chime-$(date '+%Y%m%d-%H%M').zip"
		echo -e ""
		echo -e ""
		echo -e "********************************************"
		echo -e "\nKernel compiled succesfully! Zipping up...\n"
		echo -e "********************************************"
		echo -e ""
		echo -e ""
	if [ -d "$AK3_DIR" ]; then
		cp -r $AK3_DIR AnyKernel3
	elif ! git clone -q https://github.com/itsHanibee/AnyKernel3 -b master; then
			echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
	fi
		cp $kernel AnyKernel3
		cp $dtbo AnyKernel3
		cp $dtb AnyKernel3

		rm -rf out/arch/arm64/boot
		cd AnyKernel3
		git checkout master &> /dev/null
		zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
		cd ..

	# Upload to Hosting
	curl -T "$ZIPNAME" temp.sh

        echo -e ""
        echo -e ""
        echo -e "************************************************************"
        echo -e "**                                                        **"
        echo -e "**   File name: $ZIPNAME   **"
        echo -e "**   Build completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)!    **"
        echo -e "**                                                        **"
        echo -e "************************************************************"
        echo -e ""
        echo -e ""
	else
        echo -e ""
        echo -e ""
        echo -e "*****************************"
        echo -e "**                         **"
        echo -e "**   Compilation failed!   **"
        echo -e "**                         **"
        echo -e "*****************************"
	fi
	fi
