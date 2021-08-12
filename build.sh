# SPDX-License-Identifier: GPL-3.0
# Copyright (c) 2021, Dakkshesh <dakkshesh5@gmail.com>
#bin/#!/bin/bash

export COMPILER=$1

Device="Realme XT"
Codename="RMX1921"
Maintainer="Dakkshesh"

mkdir out

KERNEL_DEFCONFIG=RMX1921_defconfig
ANYKERNEL3_DIR=$PWD/AnyKernel3
KERNELDIR=$PWD

if [[ "$COMPILER" == "CLANG" ]]; then
  COMPILERNAME=$("$KERNELDIR"/clang/bin/clang --version | head -n 1 | sed 's|\(.*\)(.*|\1|')
  export KBUILD_COMPILER_STRING=$("$KERNELDIR"/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

  sed -i 's/CONFIG_LTO=y/# CONFIG_LTO is not set/g' arch/arm64/configs/RMX1921_defconfig
  sed -i 's/# CONFIG_ARCH_SUPPORTS_LTO_CLANG is not set/CONFIG_ARCH_SUPPORTS_LTO_CLANG=y/g' arch/arm64/configs/RMX1921_defconfig
  sed -i 's/CONFIG_LTO_NONE=y/# CONFIG_LTO_NONE is not set/g' arch/arm64/configs/RMX1921_defconfig
  sed -i 's/# CONFIG_LTO_CLANG is not set/CONFIG_LTO_CLANG=y/g' arch/arm64/configs/RMX1921_defconfig
  sed -i 's/CONFIG_LTO_GCC=y/# CONFIG_LTO_GCC is not set/g' arch/arm64/configs/RMX1921_defconfig
  sed -i 's/# CONFIG_LLVM_POLLY is not set/CONFIG_LLVM_POLLY=y/g' arch/arm64/configs/RMX1921_defconfig
  sed -i '/CONFIG_THINLTO=y/d' arch/arm64/configs/RMX1921_defconfig

elif [[ "$COMPILER" == "GCC" ]]; then
  COMPILERNAME=$("$KERNELDIR"/gcc-arm64/bin/aarch64-elf-gcc --version | head -n 1 | sed "s/^[^ ]* //")
  export KBUILD_COMPILER_STRING=$("$KERNELDIR"/gcc-arm64/bin/aarch64-elf-gcc --version | head -n 1)

  sed -i 's/# CONFIG_LTO is not set/CONFIG_LTO=y/g' arch/arm64/configs/RMX1921_defconfig
  sed -i 's/CONFIG_ARCH_SUPPORTS_LTO_CLANG=y/# CONFIG_ARCH_SUPPORTS_LTO_CLANG is not set/g' arch/arm64/configs/RMX1921_defconfig
  sed -i 's/CONFIG_LTO_NONE=y/# CONFIG_LTO_NONE is not set/g' arch/arm64/configs/RMX1921_defconfig
  sed -i 's/CONFIG_LTO_CLANG=y/# CONFIG_LTO_CLANG is not set/g' arch/arm64/configs/RMX1921_defconfig
  sed -i 's/# CONFIG_LTO_GCC is not set/CONFIG_LTO_GCC=y/g' arch/arm64/configs/RMX1921_defconfig
  sed -i 's/CONFIG_LLVM_POLLY=y/# CONFIG_LLVM_POLLY is not set/g' arch/arm64/configs/RMX1921_defconfig
  sed -i '/CONFIG_THINLTO=y/d' arch/arm64/configs/RMX1921_defconfig
fi

export ARCH=arm64
telegram-send "$(date): Build Started. Device: $Device | Compiler: $COMPILERNAME"
BUILD_START=$(date +"%s")

make $KERNEL_DEFCONFIG O=out
if [[ "$COMPILER" == "CLANG" ]]; then
  export PATH=$KERNELDIR/clang/bin:$PATH
  make -j$(nproc --all) O=out \
                      PATH=$KERNELDIR/clang/bin:$PATH \
                      ARCH=arm64 \
                      CC=clang \
                      AR=llvm-ar \
                      NM=llvm-nm \
                      LD=ld.lld \
                      STRIP=llvm-strip \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      OBJSIZE=llvm-size \
                      HOSTCC=clang \
                      HOSTCXX=clang++ \
                      HOSTAR=llvm-ar \
                      HOSTLD=ld.lld \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi-
elif [[ "$COMPILER" == "GCC" ]]; then
  make -j$(nproc --all) O=out \
                      PATH=$KERNELDIR/gcc-arm64/bin/:$KERNELDIR/gcc-arm32/bin/:/usr/bin:$PATH \
                      ARCH=arm64 \
                      CC=aarch64-elf-gcc \
                      AR=aarch64-elf-ar \
                      NM=llvm-nm \
                      LD=ld.lld \
                      STRIP=aarch64-elf-strip\
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=aarch64-elf-objdump \
                      OBJSIZE=llvm-size \
                      HOSTCXX=aarch64-elf-g++ \
                      HOSTAR=llvm-ar \
                      HOSTLD=ld.lld \
                      CROSS_COMPILE=aarch64-elf- \
                      CROSS_COMPILE_ARM32=arm-eabi-
fi

if [ -f out/arch/arm64/boot/Image.gz-dtb ]; then
  cd $ANYKERNEL3_DIR/
  make clean
  cd ..

  cp $PWD/out/arch/arm64/boot/Image.gz-dtb $ANYKERNEL3_DIR/
  cp $PWD/out/arch/arm64/boot/dtbo.img $ANYKERNEL3_DIR/

  cd $ANYKERNEL3_DIR/
  make zip
  zipname=$(find -type f -name "*.zip" | cut -c 3-)
  zipsha=$(cat $zipname.sha1)
  cd ..

  BUILD_END=$(date +"%s")
  DIFF=$(($BUILD_END - $BUILD_START))
  final="
  ***************Parallax-Kernel***************
  Linux Version: <code>$(make kernelversion)</code>
  Maintainer: <code>'$Maintainer'</code>
  Compiler: <code>'$COMPILERNAME'</code>
  Device: <code>"$Device"</code>
  Codename: <code>"$Codename"</code>
  Build Date: <code>$(date +"%Y-%m-%d %H:%M")</code>
  Build Duration: <code>$(($DIFF / 60)).$(($DIFF % 60)) mins</code>
  ---------------------------------------------

  -----------------zip details-----------------
  Zip Name: <code>"$zipname"</code>
  Zip sha1: <code>"$zipsha"</code>

  -------------last commit details-------------
  Last commit (name): <code>"$(git show -s --format=%s)"</code>
  Last commit (hash): <code>"$(git rev-parse --short HEAD)"</code>
  "
  echo -e "$yellow Device:-$Device.$nocol"
  echo -e "$yellow Build Time:- Completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
  telegram-send --format html "$final"
  cd $ANYKERNEL3_DIR/
  telegram-send --file $zipname --timeout 69
  exit

else
  telegram-send "$(date): ⚠️Error kernel Compilaton failed⚠️"
  exit 1
fi