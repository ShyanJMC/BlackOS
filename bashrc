# BlackOS environment file.
# Autor;	ShyanJMC (Joaquin Manuel Crespo)
# Maintainer;	ShyanJMC (Joaquin Manuel Crespo)
# Copyright;	2021

alias ls='ls --color=auto'

unset CFLAGS

set +h
umask 022
CLFS=/home/clfs/BlackOS
LC_ALL=POSIX
PATH=/home/clfs/crosstool-ng/x-tools/aarch64-linux-gnu/bin/:/bin:/usr/bin:/usr/local/bin
export CLFS LC_ALL PATH

export ARCH="aarch64"
export CLFS_ARCH="aarch64"
export CLFS_ARM_ARCH="aarch64"
export CLFS_TARGET=aarch64-linux-gnu
export CROSS_COMPILE=aarch64-linux-gnu


# Remember set --host=aarch64-linux-gnu
# Architecture Version
export CC="${CROSS_COMPILE}-gcc -I/usr/aarch64-linux-gnu/include --sysroot=/home/clfs/crosstool-ng/x-tools/aarch64-unknown-linux-gnu/aarch64-unknown-linux-gnu/sysroot -I/usr/aarch64-linux-gnu/include"
export CXX="${CROSS_COMPILE}-g++ -I/usr/aarch64-linux-gnu/include --sysroot=/home/clfs/crosstool-ng/x-tools/aarch64-unknown-linux-gnu/aarch64-unknown-linux-gnu/sysroot -I/usr/aarch64-linux-gnu/include"
export AR="${CROSS_COMPILE}-ar"
export AS="${CROSS_COMPILE}-as"
export LD="${CROSS_COMPILE}-ld --sysroot=/home/clfs/crosstool-ng/x-tools/aarch64-unknown-linux-gnu/aarch64-unknown-linux-gnu/sysroot"
export RANLIB="${CROSS_COMPILE}-ranlib"
export READELF="${CROSS_COMPILE}-readelf"
export STRIP="${CROSS_COMPILE}-strip"
