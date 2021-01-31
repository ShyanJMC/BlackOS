# Linux kernel
* Seems like the kernel Linux can not be compiled for support more than one SOC, I don't know the reason but I think that this is because as a SOC (System on a Chip) is a complete machine in a chip, if I compiled with the support for many of them, will be collisions.

* Seems like the kernel Linux can not be compiled using a crosstoolchain with uClibc, requires Glibc (becuase is more completed). Take in consideration that the hardware, linux and the C library are very very close as dependencies and function.


