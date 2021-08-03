#bin/#!/bin/bash

pacman -Syu --noconfirm --needed git bc inetutils zip libxml2 python3 \
                                 jre-openjdk jdk-openjdk flex bison libc++ python-pip

git clone -q --depth=1 https://github.com/dakkshesh07/parallax_kernel_realme_rmx1921.git -b schedhorizon $HOME/Kernel
git clone -q --depth=1 https://gitlab.com/ElectroPerf/atom-x-clang.git $HOME/Kernel/clang
pip3 -q install telegram-send
echo 'Sources and Api installed...'

sed -i s/placeholder1/${BOT_API_KEY}/g telegram-send.conf
sed -i s/placeholder2/${CHAT_ID}/g telegram-send.conf
mkdir $HOME/.config
mv telegram-send.conf $HOME/.config/telegram-send.conf
mv build.sh $HOME/Kernel/build.sh
cd $HOME/Kernel
bash $HOME/Kernel/build.sh
