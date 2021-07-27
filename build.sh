#bin/#!/bin/bash
telegram-send "$(date): Build Started. Device: Realme XT"
rm -r out
mkdir out
make clean && make distclean && make mrproper

KERNEL_DEFCONFIG=RMX1921_defconfig
Device="Realme XT"
ANYKERNEL3_DIR=$PWD/AnyKernel3/
KERNELDIR=$PWD/
FINAL_KERNEL_ZIP=parallax_test_v1.zip
PATH="${PWD}/clang/bin:${PATH}"
export KBUILD_COMPILER_STRING="$(${PWD}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
export ARCH=arm64
export SUBARCH=arm32
MAKE="./makeparallel"
BUILD_START=$(date +"%s")

make $KERNEL_DEFCONFIG O=out
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      SUBARCH=arm32 \
                      CC=clang \
                      HOSTCC=clang \
                      HOSTCXX=clang++ \
                      HOSTLD=ld.lld \
                      AS=llvm-as \
                      AR=llvm-ar \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                      NM=llvm-nm \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip

if [ -f out/arch/arm64/boot/Image.gz-dtb ]; then
  rm -rf $ANYKERNEL3_DIR/Image.gz-dtb
  rm -rf $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP

  cp $PWD/out/arch/arm64/boot/Image.gz-dtb $ANYKERNEL3_DIR/
  cp $PWD/out/arch/arm64/boot/dtbo.img $ANYKERNEL3_DIR/

  cd $ANYKERNEL3_DIR/
  zip -r9 $FINAL_KERNEL_ZIP * -x README $FINAL_KERNEL_ZIP
  mv $ANYKERNEL3_DIR/$FINAL_KERNEL_ZIP $KERNELDIR/$FINAL_KERNEL_ZIP
  cd ..

  BUILD_END=$(date +"%s")
  DIFF=$(($BUILD_END - $BUILD_START))
  final="
  ***************Parallax-Kernel***************
  Linux Version: <code>$(make kernelversion)</code>
  Maintainer: <code>Dakkshesh</code>
  Device: <code>$Device</code>
  Codename: <code>RMX1921</code>
  Build Date: <code>$(date +"%Y-%m-%d %H:%M")</code>
  Build Duration: <code>$(($DIFF / 60)).$(($DIFF % 60)) mins</code>
  Last commit (name): <code>"$(git show -s --format=%s)"</code>
  Last commit (hash): <code>"$(git rev-parse --short HEAD)"</code>
  "
  telegram-send --format html "$final"
  telegram-send --file $KERNELDIR/$FINAL_KERNEL_ZIP
  exit

else
  telegram-send "$(date): Build Failed, Go Die"
  exit 1
fi
