# BlackOS
A Linux system from scratch designed for ARMv8 System On a Chip (known as SOC). 

It is designed to be as minimal as possible, so you will find a very basic and minimal system. The reason for this is you can adapt your applications to your requeriments. 

Think about this system like a minimal OS for to rebuild the humanity if you are in an apocalypse or in a place without Internet connection and you have only a few SBCs without much power and need digital services. 

If you need more documentation about the project, go to the folder "Documentation".

# How to use it
Go to "Releases" page, download the release of your chooice. Then uncompress it, compile the kernel and follow the indications for your Single Board Computer model and then boot. Also I was mentioned before, is best that you copy the kernel and firmware from a working distro in /boot and /modules and change "cmdline.txt" or the respective file to load the right partition and the right init; "/sbin/init".

# Enumeration and name convention
BlackOS follow this standard to enumerate the releases;

> [MV].[NF].[NFI]-[ABS]

MV: Major release version. v1 v2 v3 etc. Major Release means a major update or upgrade to the Software, which includes significant enhancements and/or a major redesign of the Software.

NF: Number of Features. Indicate the number of features included into the major release.

NFI: Number of FIxes. Indicate the number of features included into the major release, at higher number more fixes are in those major release version.

ABS: Alpha Beta Stable. Indicate the state of the current release. "Alpha" means the release is in current development and is not stable, also expect a higher number of changes/fixes in the software. "Beta" means the release is in quality tests to fix issues and is not stable yet and ready to use in production. "Stable" means the release was tested and is considered ready for production.

## Files
> bashrc

Is the .bashrc which contains all variables.

> create_base_system.sh

Is the bash scripting file which contains functions and commands to build the system without going to CLFS and doing each step to build BlackOS from scratch.

In the "config" folder, there are some kernel's configurations files (.config) depending on the SBC. But I really don't reccomend to compile your own kernel because probably many of you will fail on it (you will need to know the bootloader support for kernel's images types, which SOC supports inside the kernel, the specifics parts of that SOC and many other characteristics for that board which you prefer to use with BlackOS). My reccomendation is to use the kernel of another distribution that can run in that board.

# Copyright
Designed and built by ShyanJMC (Joaquin Manuel Crespo). <br>
The programs in this project are under many licenses (like GPLv2, GPLv3, MIT and others), so if you want the BlackOS's source code go to;
* https://github.com/ShyanJMC/LinuxFromScratch-Sources 

# Contact
If you want or need to contact me, you can make do it through:
* https://ar.linkedin.com/in/joaquin-mcrespo
* joaquincrespo96@gmail.com
* shyanjmc@protonmail.com 
