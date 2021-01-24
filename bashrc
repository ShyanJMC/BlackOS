alias ls='ls --color=auto'

export CLFS_HOST=x86_64-cross-linux-gnu
unset CFLAGS

set +h
umask 022
CLFS=/home/clfs/BlackOS
LC_ALL=POSIX
PATH=/home/clfs/crosstool-ng/x-tools/aarch64-linux-uclibc/bin/:/bin:/usr/bin
export CLFS LC_ALL PATH

export ARCH=arm64
export CLFS_ARCH=arm64
export CLFS_ARM_ARCH="armv8"
export CLFS_TARGET=aarch64-linux-uclibc

# Architecture Version
export CC="aarch64-linux-uclibc-gcc --sysroot=/home/clfs/BlackOS/targetfs"
export CXX="aarch64-linux-uclibc-g++ --sysroot=/home/clfs/BlackOS/targetfs"
export AR="aarch64-linux-uclibc-ar"
export AS="aarch64-linux-uclibc-as"
export LD="aarch64-linux-uclibc-ld --sysroot=/home/clfs/BlackOS/targetfs"
export RANLIB="aarch64-linux-uclibc-ranlib"
export READELF="aarch64-linux-uclibc-readelf"
export STRIP="aarch64-linux-uclibc-strip"
