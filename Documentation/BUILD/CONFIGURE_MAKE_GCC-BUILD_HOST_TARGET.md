This document is part of BlackOS project.
Copyright 2021 Joaquin (AKA; ShyanJMC ) Crespo.

=========================================================
When you build a program for a cross architecture, for
example; you build a program in x86_64 for Aarch64
(ARM 64 bits) you need know when you will need specify;
--build --host and --target.

Keep this examples;
- You build it in x86_64.
- You execute it in ARM64 (Aarch64).

--build = is the toolchain in your machine to build the
cross-toolchain (your system).

--host = is the toolchain where you will compile the program 
(x86) to work for the target (arm64). This toolchain execute
in x86_64 to compile a program for ARM64. If you already
have a croos toolchain (like croostool-ng installed and 
built it in your system you only need specify the program).

--target = is where you will execute the final program.

So, if you want compile Firefox in a system x86_64 for
ARM64 you will need use;

NOTE; Keep in mind that you don't need specify an
arquitecture. You MUST specify the toolchain (the tools
that are used to compile).

--build=x86_64-pc-linux-gnu
--host=aarch64-linux-gnu
--target=aarch64-linux-gnu
