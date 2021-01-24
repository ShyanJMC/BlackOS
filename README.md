# BlackOS
A Linux system from scratch designed for ARMv8 System On a Chip (known as SOC). 

Is designed to be as minimal as possible, so expect to have a very base and minimal system. The reason of this is you can adapt your aplications for your requeriments.
The Cross Toolchain were build with "crosstool-NG" and the system was build using CLFS (Cross Linux From Scratch).

## Environment Variables and bashrc file
These are my variables inside ".bashrc" file:

> export CLFS_HOST=x86_64-cross-linux-gnu

> unset CFLAGS

> set +h

> umask 022

> CLFS=/home/clfs/BlackOS

> LC_ALL=POSIX

> PATH=${CLFS}/cross-tools/bin:/bin:/usr/bin:/home/clfs/crosstool-ng/x-tools/arm-linux-uclibcgnueabi/bin/

> export CLFS LC_ALL PATH

> export ARCH=arm64

> export CLFS_ARCH=arm64

> export CLFS_ARM_ARCH="armv8"

> export CLFS_TARGET=aarch64-linux-gnu

> export CC="aarch64-linux-gnu-gcc --sysroot=/home/clfs/BlackOS/targetfs"

> export CXX="aarch64-linux-gnu-g++ --sysroot=/home/clfs/BlackOS/targetfs"

> export AR="aarch64-linux-gnu-ar"

> export AS="aarch64-linux-gnu-as"

> export LD="aarch64-linux-gnu-ld --sysroot=/home/clfs/BlackOS/targetfs"

> export RANLIB="aarch64-linux-gnu-ranlib"

> export READELF="aarch64-linux-gnu-readelf"

> export STRIP="aarch64-linux-gnu-strip"

# Re Build kernel
If you have a platform which is not ARMv8 or need to rebuild the kernel need this;

First, download the Linux kernel (or clone my LinuxFromScratch Repo), uncompress the linux-4.20.8 it and then inside the folder execute; 
> ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}- make [defconfig_chip]

To see the platforms and chips support ( the [defconfig_chip] before ) execute;
> ls arch/arm/configs

Then, configure it;
> ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}- make menuconfig

And then compile it (don't use zImage because in ARM64 is not needed);
> ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}- make -j[NUMBER_OF_CPUS_+1] Image modules dtbs

When it's finished copy the respective files;
> cp arch/arm/boot/dts/*.dtb $CLFS/targetfs/boot/

> cp arch/arm/boot/dts/overlays/\*.dtb\* $CLFS/targetfs/boot/overlays/

> cp arch/arm/boot/dts/overlays/README $CLFS/targetfs/boot/overlays/

> cp arch/arm/boot/Image $CLFS/targetfs/boot/"your_image".img

At least, edit the boot/config.txt to indicate your kernel;
> kernel="your_image".img

## Resources
Also you can check these tutorials;
> https://www.stephenwagner.com/2020/03/17/how-to-compile-linux-kernel-raspberry-pi-4-raspbian/

> https://www.barebox.org/doc/latest/boards/bcm2835.html

### Note
First alpha was for ARMv8 because is the newest, but is so new that qemu do not support it yet.

# Copyright
Designed and built by ShyanJMC (Joaquin Manuel Crespo). <br>
The programs under this project are under many licenses (like GPLv2, GPLv3, MIT and others), so if you want the BlackOS's source code go to;
* https://github.com/ShyanJMC/LinuxFromScratch-Sources 

# Usage
0. Go to Github's releases ( https://github.com/ShyanJMC/BlackOS/releases ) and download it.
1. Extract it with "-p" in "tar". 
2. Create two partitions, the first one with FAT32 (200Mb should be enough), make it booteable in your partitions tool (fsck, gparted, etc) and the second one with EXT4.
3. Mount the first partition (FAT32) in /boot into the second one (Ext4) and copy the files with "-p" so as to not change the permissions.

. Root password is empty, so in the login screen log in as root without password.

Also you can check the partition steps in;
> https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3 

# Contact
If you want or need to contact me, you can do it through:
* https://ar.linkedin.com/in/joaquin-mcrespo
* joaquincrespo96@gmail.com
