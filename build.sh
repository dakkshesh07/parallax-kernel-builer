#bin/#!/bin/bash
telegram-send "$(date): Build Started. Device: Realme XT"
rm -r out
mkdir out
make clean && make distclean && make mrproper

KERNEL_DEFCONFIG=RMX1921_defconfig
sed -i '/CONFIG_THINLTO=y/d' arch/arm64/configs/RMX1921_defconfig
Device="Realme XT"
ANYKERNEL3_DIR=$PWD/AnyKernel3/
KERNELDIR=$PWD/
PATH="${PWD}/clang/bin:${PATH}"
export KBUILD_COMPILER_STRING="$(${PWD}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export ARCH=arm64
MAKE="./makeparallel"
BUILD_START=$(date +"%s")

make $KERNEL_DEFCONFIG O=out
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      AR=llvm-ar \
                      NM=llvm-nm \
                      LD=ld.lld \
                      STRIP=llvm-strip \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      OBJSIZE=llvm-size \
                      READELF=llvm-readelf \
                      HOSTCC=clang \
                      HOSTCXX=clang++ \
                      HOSTAR=llvm-ar \
                      HOSTLD=ld.lld \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \

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
  Maintainer: <code>Dakkshesh</code>
  Device: <code>Realme XT</code>
  Codename: <code>RMX1921</code>
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
  telegram-send "$(date): Build Failed, Go Die"
  exit 1
fi
