# BlackOS
A Linux From Scratch system designed for ARMv7 System On a Chip (as know as; SOC).

# Supported SOCs platforms
BlackOS is compiled for ARMv7. So if you have an ARMv8 (like Raspberry Pi 4 for example), you need enable the AArch32 mode to execute it. 

Also the Linux kernel is compiled to support the chip BCM2835 (Raspberry Pi use it). So if you need support for another platform, you must re compile the Linux's kernel.

First, download the kernel Linux (or clone my LinuxFromScratch Repo), uncompress it and then inside the folder do; 
> ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}- make [defconfig_chip]

To see the platforms and chips support ( the [defconfig_chip] before ) do;
> ls arch/arm/configs

Then, configure it;
> ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}- make menuconfig

And then compile it;
> ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}- make -j[NUMBER_OF_CPUS_+1] zImage modules dtbs

### Note
First alpha was for ARMv8 because is the most new, but is so new that qemu not support yet.

# Copyright
Designed and build it by ShyanJMC (Joaquin Manuel Crespo). <br>
The programs under this project are in many licenses (like GPLv2, GPLv3, MIT and others), so if you want the BlackOS's source code see;
* https://github.com/ShyanJMC/LinuxFromScratch-Sources 

# Usage
0. Go to Github's releases ( https://github.com/ShyanJMC/BlackOS/releases ) and download it.
1. Extract it with "-p" in "tar". 
2. Create two partitions, the first with FAT32 (100Mb should be enough), make it booteable in your partitions tool (fsck, gparted, etc) and the second with EXT4.
3. Mount the first partition (FAT32) in /boot into the second (Ext4) and copy the files with "-p" to not change the permissions.
. To boot the Linux system;
> bootm /path/to/zImage

In BlackOS the path is "/boot". 

. Root's password is empty, so in the login screen ingress as root without password.

Also you can check the partition steps in;
> https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3 

# Contact
If you want or need contact me, you can do trough:
* https://ar.linkedin.com/in/joaquin-mcrespo
* joaquincrespo96@gmail.com
