# BlackOS
A Linux From Scratch system designed for ARMv7 System On a Chip (as know as; SOC).

### Note
First alpha was for ARMv8 because is the most new, but is so new that qemu not support yet (and I will not use a Raspberry Pi 4 for do the test).

# Copyright
Designed and build it by ShyanJMC (Joaquin Manuel Crespo). <br>
The programs under this project are in many licenses (like GPLv2, GPLv3, MIT and others), so if you want the BlackOS's source code see;
* https://github.com/ShyanJMC/LinuxFromScratch-Sources 

# Usage
0. Go to Github's releases ( https://github.com/ShyanJMC/BlackOS/releases ) and download it.
1. Extract it with "-p" in "tar". Do it in a SDCARD in EXT4 and make it booteable in your partitions tool (fsck, gparted, etc).
2. To boot the Linux system;
> bootm /path/to/zImage

In BlackOS the path is "/boot". 

3. Root's password is empty, so in the login screen ingress as root without password.

# Contact
If you want or need contact me, you can do trough:
* https://ar.linkedin.com/in/joaquin-mcrespo
* joaquincrespo96@gmail.com
