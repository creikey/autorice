#!/bin/bash

cd
mkdir -p software
cd software
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
yay --builddir .
yay --save
