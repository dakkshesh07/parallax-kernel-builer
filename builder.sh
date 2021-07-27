#bin/#!/bin/bash

pacman -Syu --noconfirm --needed git bc inetutils zip libxml2 python3 \
                                 jre-openjdk jdk-openjdk flex bison libc++ python-pip

git clone -q --depth=1 https://github.com/dakkshesh07/parallax_kernel_realme_rmx1921.git -b new $HOME/Kernel
git clone -q --depth=1 https://github.com/kdrag0n/proton-clang.git $HOME/Kernel/clang
pip3 -q install telegram-send
echo 'Sources and Api installed...'

sed -i s/placeholder1/${BOT_API_KEY}/g telegram-send.conf
sed -i s/placeholder2/${CHAT_ID}/g telegram-send.conf
mkdir $HOME/.config
mv telegram-send.conf $HOME/.config/telegram-send.conf
mv build.sh $HOME/Kernel/build.sh
cd $HOME/Kernel
git reset --hard d6232317d4d0a2856d1fabd362b7b5f680e5c158
bash $HOME/Kernel/build.sh
