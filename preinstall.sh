#!/bin/bash
set -e

apt-get update --fix-missing && \
    apt-get install -y make build-essential git wget cmake gawk 

apt-get install -y libtinfo-dev 
apt-get install -y libcap-dev zlib1g-dev

# llvm-4.0
apt-get install -y libtinfo5
apt-get install -y xz-utils
wget -q https://releases.llvm.org/4.0.0/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz
tar -xf clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz
rm clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz

cp -r clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10 /usr/llvm
cp -r /usr/llvm/bin/* /usr/bin 
cp -r /usr/llvm/lib/* /usr/lib
cp -r /usr/llvm/include/* /usr/include 
cp -r /usr/llvm/share/* /usr/share

apt-get install -y python3 python3-dev python3-pip
pip3 install --upgrade pip
pip3 install wllvm
