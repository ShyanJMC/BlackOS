# BlackOS
A Linux system from scratch designed for ARMv8 System On a Chip (known as SOC). 

Is designed to be as minimal as possible, so expect to have a very base and minimal system. The reason of this is you can adapt your aplications for your requeriments. 

Think this system like a minimal OS to rebuild the humanity if you are in an apocalipsis or in a place without Internet and you have only a few SBC without much power and need digital services. In the future I will provide the source code of some projects like Lighttpd and others, so you can quickly copy it inside BlackOS and compile them.

In the firsts steps of this proyect, I built it for Raspberry Pi and Pine Rock64 but after see that there are so many SBCs in the world(each one with specifics configurations to boot), I choose make a Linux system without kernel. So, you download the release, you compile the kernel for the ARCH target and then you integrate the firmware and the bootloader into it to boot BlackOS, more easy and will do BlackOS more portable. 

# How to use
Go to "Releases" page, download the release of your choise. Uncompress it, compile the kernel and follow the indications for your Single Board Computer model and then boot.

## Requeriments to compile kernel or build from scratch.
0. My repo linuxfromscratch-sources cloned into; /home/clfs/ and all tarballs uncompressed.
1. crosstools-ng (you can find it in my linuxfromscratch-resources repo). Built it with "armv8-a" and GlibC option.
2. clfs user to build it.
3. crosstools-ng toolchain builded with uclibc in the folder; /home/clfs/crosstool-ng/{x-tools,src,etc} you can configure this when you build the toolchain with; 
> ct-ng menuconfig

> ct-ng build

## Files
> blackosrc

Is the .bashrc which contains all variables.

> create_base_system.sh

Is the bash scripting file which contains functions and commands to build the system without go to CLFS and do each step to build BlackOS from scratch.

In the "config" folder, there are some kernel's configurations files (.config) depending of the SBC.

## Resources
Also you can check these tutorials;
> https://www.stephenwagner.com/2020/03/17/how-to-compile-linux-kernel-raspberry-pi-4-raspbian/

> https://www.barebox.org/doc/latest/boards/bcm2835.html

# Copyright
Designed and built by ShyanJMC (Joaquin Manuel Crespo). <br>
The programs under this project are under many licenses (like GPLv2, GPLv3, MIT and others), so if you want the BlackOS's source code go to;
* https://github.com/ShyanJMC/LinuxFromScratch-Sources 

# Contact
If you want or need to contact me, you can do it through:
* https://ar.linkedin.com/in/joaquin-mcrespo
* joaquincrespo96@gmail.com
