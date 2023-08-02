#!/bin/bash
set -e

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
##

# if [ ! -d "$FUZZER/repo" ]; then
#     echo "fetch.sh must be executed first."
#     exit 1
# fi

echo 'export LLVM_COMPILER=clang' >> "$HOME/.bashrc"
echo 'export PATH="/usr/local/bin:$PATH"' >> "$HOME/.bashrc"
source "$HOME/.bashrc"
wllvm++ $CXXFLAGS -std=c++11 -c "$FUZZER/repo/driver.cpp" -fPIC -o "$OUT/driver.o"
