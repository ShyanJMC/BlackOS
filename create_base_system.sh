#!/bin/bash
# Maintainer;	ShyanJMC (Joaquin Manuel Crespo)
# Autor:	ShyanJMC (Joaquin Manuel Crespo)
# Email:	joaquincrespo96@gmail.com
# Copyright; 	2021(c)

################################################
############## Variables zone ##################
################################################

export CPUTHREAD=$(cat /proc/cpuinfo | grep processor | wc | cut -d' ' -f7)
export BUSYBOX_BRANCH=remotes/origin/1_33_stable
export DROPBEAR_TAG=tag/DROPBEAR_2020.81
export ZLIB_TAG=tags/v1.2.11

###########################################################################
######################## Functions zone ###################################
###########################################################################

function create_folders(){
mkdir -pv ${CLFS}/targetfs/{bin,boot,dev,etc,home,lib/{firmware,modules}}
mkdir -pv ${CLFS}/targetfs/{mnt,opt,proc,sbin,srv,sys}
mkdir -pv ${CLFS}/targetfs/var/{cache,lib,local,lock,log,opt,run,spool}
install -dv -m 0750 ${CLFS}/targetfs/root
install -dv -m 1777 ${CLFS}/targetfs/{var/,}tmp
mkdir -pv ${CLFS}/targetfs/usr/{,local/}{bin,include,lib,sbin,share,src}
}

function link_mtab(){
ln -svf ../proc/mounts ${CLFS}/targetfs/etc/mtab
}

function create_root(){
cat > ${CLFS}/targetfs/etc/passwd << "EOF"
root::0:0:root:/root:/bin/ash
EOF
}

function libgcc_s_so_1(){
cp -v /home/clfs/crosstool-ng/x-tools/aarch64-linux-gnu/aarch64-linux-gnu/lib64/libgcc_s.so.1 ${CLFS}/targetfs/lib/libgcc_s.so.1
# ${CLFS_TARGET}-strip ${CLFS}/targetfs/lib/libgcc_s.so.1
}

function musl(){
mkdir /home/clfs/linuxfromscratch-sources/musl/build
cd /home/clfs/linuxfromscratch-sources/musl/build
../configure CROSS_COMPILE=${CLFS_TARGET}- --prefix=/ --disable-static --target=${CLFS_TARGET}
make -j$CPUTHREAD
DESTDIR=${CLFS}/targetfs make install-libs
}

function busybox(){
cd /home/clfs/linuxfromscratch-sources/busybox

git checkout $BUSYBOX_BRANCH

# Check if ".config" file exist
if [ -f ".config"  ]; then
	# If exist execute
	make menuconfig
else
	# If not, execute
	make distclean
	make ARCH=${CLFS_ARCH} defconfig
	make menuconfig
fi

# For some reason sometimes this happen. So, yes, this is not the best fix but works.
sed -i 's/aarch64-linux-gnugcc/aarch64-linux-gnu-gcc/g' scripts/gcc-version.sh

sed -i 's/\(CONFIG_\)\(.*\)\(INETD\)\(.*\)=y/# \1\2\3\4 is not set/g' .config
sed -i 's/\(CONFIG_IFPLUGD\)=y/# \1 is not set/' .config
sed -i 's/\(CONFIG_FEATURE_WTMP\)=y/# \1 is not set/' .config
sed -i 's/\(CONFIG_FEATURE_UTMP\)=y/# \1 is not set/' .config
sed -i 's/\(CONFIG_UDPSVD\)=y/# \1 is not set/' .config
sed -i 's/\(CONFIG_TCPSVD\)=y/# \1 is not set/' .config
CC='aarch64-linux-gnu-gcc --sysroot=/usr/aarch64-linux-gnu/' make ARCH="${CLFS_ARCH}" CROSS_COMPIlE="${CLFS_TARGET}-" -j$CPUTHREAD
make ARCH="${CLFS_ARCH}" CROSS_COMPILE="${CLFS_TARGET}-" CONFIG_PREFIX="${CLFS}/targetfs" install
}

function ianaetc(){
cd /home/clfs/linuxfromscratch-sources/iana-etc-2.30
patch -Np1 -i ../iana-etc-2.30-update-2.patch
make get
make STRIP=yes
make DESTDIR=${CLFS}/targetfs install
}

function fstab(){
cat > ${CLFS}/targetfs/etc/fstab << "EOF"
# file-system  mount-point  type   options          dump  fsck
EOF
}

#function linux(){
#	cd /home/clfs/linuxfromscratch-sources/linux-5.10.9
#	make mrproper
#	make ARCH=arm64 defconfig
#	make ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}- menuconfig
#	ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}- make -j$CPUTHREAD Image modules dtbs
#	make ARCH=${CLFS_ARCH} CROSS_COMPILE=${CLFS_TARGET}- INSTALL_MOD_PATH=${CLFS}/targetfs modules_install
#	cp arch/arm64/boot/dts/*.dtb $CLFS/targetfs/boot/
#	cp arch/arm64/boot/dts/overlays/*.dtb* $CLFS/targetfs/boot/overlays/
#	cp arch/arm64/boot/dts/overlays/README $CLFS/targetfs/boot/overlays/
#	cp arch/arm64/boot/Image $CLFS/targetfs/boot/blackos.img
#	echo "kernel=blackos.img" >> $CLFS/targetfs/boot/config.txt
#}

function cross_scripts(){
	cd /home/clfs/linuxfromscratch-sources/cross-lfs-bootscripts-embedded
	make DESTDIR=${CLFS}/targetfs install-bootscripts
}

function mdev(){
cat > ${CLFS}/targetfs/etc/mdev.conf<< "EOF"
# /etc/mdev/conf

# Devices:
# Syntax: %s %d:%d %s
# devices user:group mode

# null does already exist; therefore ownership has to be changed with command
null    root:root 0666  @chmod 666 $MDEV
zero    root:root 0666
grsec   root:root 0660
full    root:root 0666

random  root:root 0666
urandom root:root 0444
hwrandom root:root 0660

# console does already exist; therefore ownership has to be changed with command
#console        root:tty 0600   @chmod 600 $MDEV && mkdir -p vc && ln -sf ../$MDEV vc/0
console root:tty 0600 @mkdir -pm 755 fd && cd fd && for x in 0 1 2 3 ; do ln -sf /proc/self/fd/$x $x; done

fd0     root:floppy 0660
kmem    root:root 0640
mem     root:root 0640
port    root:root 0640
ptmx    root:tty 0666

# ram.*
ram([0-9]*)     root:disk 0660 >rd/%1
loop([0-9]+)    root:disk 0660 >loop/%1
sd[a-z].*       root:disk 0660 */lib/mdev/usbdisk_link
hd[a-z][0-9]*   root:disk 0660 */lib/mdev/ide_links
md[0-9]         root:disk 0660

tty             root:tty 0666
tty[0-9]        root:root 0600
tty[0-9][0-9]   root:tty 0660
ttyS[0-9]*      root:tty 0660
pty.*           root:tty 0660
vcs[0-9]*       root:tty 0660
vcsa[0-9]*      root:tty 0660

ttyLTM[0-9]     root:dialout 0660 @ln -sf $MDEV modem
ttySHSF[0-9]    root:dialout 0660 @ln -sf $MDEV modem
slamr           root:dialout 0660 @ln -sf $MDEV slamr0
slusb           root:dialout 0660 @ln -sf $MDEV slusb0
fuse            root:root  0666

# dri device
card[0-9]       root:video 0660 =dri/

# alsa sound devices and audio stuff
# pcm.*           root:audio 0660 =snd/
# control.*       root:audio 0660 =snd/
# midi.*          root:audio 0660 =snd/
# seq             root:audio 0660 =snd/
# timer           root:audio 0660 =snd/

# adsp            root:audio 0660 >sound/
# audio           root:audio 0660 >sound/
# dsp             root:audio 0660 >sound/
# mixer           root:audio 0660 >sound/
# sequencer.*     root:audio 0660 >sound/

# misc stuff
agpgart         root:root 0660  >misc/
psaux           root:root 0660  >misc/
rtc             root:root 0664  >misc/

# input stuff
event[0-9]+     root:root 0640 > input/
mice            root:root 0640 > input/
mouse[0-9]      root:root 0640 > input/
ts[0-9]         root:root 0600 > input/


# v4l stuff
vbi[0-9]        root:video 0660 >v4l/
video[0-9]      root:video 0660 >v4l/

# dvb stuff
dvb.*           root:video 0660 */lib/mdev/dvbdev

# load drivers for usb devices
usbdev[0-9].[0-9]       root:root 0660 */lib/mdev/usbdev
usbdev[0-9].[0-9]_.*    root:root 0660

# net devices
tun[0-9]*       root:root 0600 > net/
tap[0-9]*       root:root 0600 > net/

# zaptel devices
zap(.*)         root:dialout 0660 =zap/%1
dahdi!(.*)      root:dialout 0660 =dahdi/%1

# raid controllers
cciss!(.*)      root:disk 0660 =cciss/%1
ida!(.*)        root:disk 0660 =ida/%1
rd!(.*)         root:disk 0660 =rd/%1

sr[0-9]         root:cdrom 0660 @ln -sf $MDEV cdrom 

# hpilo
hpilo!(.*)      root:root 0660 =hpilo/%1

# xen stuff
xvd[a-z]        root:root 0660 */lib/mdev/xvd_links
EOF

}

function bprofile(){
cat > ${CLFS}/targetfs/etc/profile << "EOF"
# /etc/profile

# Set the initial path
export PATH=/bin:/usr/bin

if [ `id -u` -eq 0 ] ; then
        PATH=/bin:/sbin:/usr/bin:/usr/sbin
        unset HISTFILE
fi

# Setup some environment variables.
export USER=`id -un`
export LOGNAME=$USER
export HOSTNAME=`/bin/hostname`
export HISTSIZE=1000
export HISTFILESIZE=1000
export PAGER='/bin/more '
export EDITOR='/bin/vi'

# End /etc/profile
EOF
}


function inittab(){
cat > ${CLFS}/targetfs/etc/inittab<< "EOF"
# /etc/inittab
# https://git.busybox.net/busybox/tree/examples/inittab 
# /etc/inittab init(8) configuration for BusyBox
#
# Copyright (C) 1999-2004 by Erik Andersen <andersen@codepoet.org>
#
#
# Note, BusyBox init doesn't support runlevels.  The runlevels field is
# completely ignored by BusyBox init. If you want runlevels, use sysvinit.
#
#
# Format for each entry: <id>:<runlevels>:<action>:<process>
#
# <id>: WARNING: This field has a non-traditional meaning for BusyBox init!
#
#	The id field is used by BusyBox init to specify the controlling tty for
#	the specified process to run on.  The contents of this field are
#	appended to "/dev/" and used as-is.  There is no need for this field to
#	be unique, although if it isn't you may have strange results.  If this
#	field is left blank, then the init's stdin/out will be used.
#
# <runlevels>: The runlevels field is completely ignored.
#
# <action>: Valid actions include: sysinit, wait, once, respawn, askfirst,
#                                  shutdown, restart and ctrlaltdel.
#
#	sysinit actions are started first, and init waits for them to complete.
#	wait actions are started next, and init waits for them to complete.
#	once actions are started next (and not waited for).
#
#	askfirst and respawn are started next.
#	For askfirst, before running the specified process, init displays
#	the line "Please press Enter to activate this console"
#	and then waits for the user to press enter before starting it.
#
#	shutdown actions are run on halt/reboot/poweroff, or on SIGQUIT.
#	Then the machine is halted/rebooted/powered off, or for SIGQUIT,
#	restart action is exec'ed (init process is replaced by that process).
#	If no restart action specified, SIGQUIT has no effect.
#
#	ctrlaltdel actions are run when SIGINT is received
#	(this might be initiated by Ctrl-Alt-Del key combination).
#	After they complete, normal processing of askfirst / respawn resumes.
#
#	Note: unrecognized actions (like initdefault) will cause init to emit
#	an error message, and then go along with its business.
#
# <process>: Specifies the process to be executed and it's command line.
#
# Note: BusyBox init works just fine without an inittab. If no inittab is
# found, it has the following default behavior:
#	::sysinit:/etc/init.d/rcS
#	::askfirst:/bin/sh
#	::ctrlaltdel:/sbin/reboot
#	::shutdown:/sbin/swapoff -a
#	::shutdown:/bin/umount -a -r
#	::restart:/sbin/init
#	tty2::askfirst:/bin/sh
#	tty3::askfirst:/bin/sh
#	tty4::askfirst:/bin/sh
#
# Boot-time system configuration/initialization script.
# This is run first except when booting in single-user mode.
#
# ::sysinit:/etc/init.d/rcS

# /bin/sh invocations on selected ttys
#
# Note below that we prefix the shell commands with a "-" to indicate to the
# shell that it is supposed to be a login shell.  Normally this is handled by
# login, but since we are bypassing login in this case, BusyBox lets you do
# this yourself...
#
# Start an "askfirst" shell on the console (whatever that may be)
::sysinit:-/bin/sh

# Start an "askfirst" shell on /dev/tty2-4
tty2::askfirst:-/bin/sh
tty3::askfirst:-/bin/sh
tty4::askfirst:-/bin/sh

# /sbin/getty invocations for selected ttys
tty4::respawn:/sbin/getty 38400 tty5
tty5::respawn:/sbin/getty 38400 tty6

# Example of how to put a getty on a serial line (for a terminal)
#::respawn:/sbin/getty -L ttyS0 9600 vt100
#::respawn:/sbin/getty -L ttyS1 9600 vt100
#
# Example how to put a getty on a modem line.
#::respawn:/sbin/getty 57600 ttyS2

# Stuff to do when restarting the init process
::restart:/sbin/init

# Stuff to do before rebooting
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
::shutdown:/sbin/swapoff -a

EOF
}

function hostname(){
	echo "blackos" > ${CLFS}/targetfs/etc/HOSTNAME
}

function hostfile(){
cat > ${CLFS}/targetfs/etc/hosts << "EOF"
# Begin /etc/hosts (network card version)

127.0.0.1 localhost blackos

# End /etc/hosts (network card version)
EOF
}

function networkinterfaces(){


mkdir -pv ${CLFS}/targetfs/etc/network/if-{post-{up,down},pre-{up,down},up,down}.d
mkdir -pv ${CLFS}/targetfs/usr/share/udhcpc

cat > ${CLFS}/targetfs/etc/network/interfaces << "EOF"
auto eth0
iface eth0 inet dhcp
EOF

cat > ${CLFS}/targetfs/usr/share/udhcpc/default.script << "EOF"
#!/bin/sh
# udhcpc Interface Configuration
# Based on http://lists.debian.org/debian-boot/2002/11/msg00500.html
# udhcpc script edited by Tim Riker <Tim@Rikers.org>

[ -z "$1" ] && echo "Error: should be called from udhcpc" && exit 1

RESOLV_CONF="/etc/resolv.conf"
[ -n "$broadcast" ] && BROADCAST="broadcast $broadcast"
[ -n "$subnet" ] && NETMASK="netmask $subnet"

case "$1" in
        deconfig)
                /sbin/ifconfig $interface 0.0.0.0
                ;;

        renew|bound)
                /sbin/ifconfig $interface $ip $BROADCAST $NETMASK

                if [ -n "$router" ] ; then
                        while route del default gw 0.0.0.0 dev $interface ; do
                                true
                        done

                        for i in $router ; do
                                route add default gw $i dev $interface
                        done
                fi

                echo -n > $RESOLV_CONF
                [ -n "$domain" ] && echo search $domain >> $RESOLV_CONF
                for i in $dns ; do
                        echo nameserver $i >> $RESOLV_CONF
                done
                ;;
esac

exit 0
EOF

chmod +x ${CLFS}/targetfs/usr/share/udhcpc/default.script
}

function dropbear(){
cd /home/clfs/linuxfromscratch-sources/dropbear
git checkout $DROPBEAR_TAG
sed -i 's/.*mandir.*//g' Makefile.in
CC=$CC CFLAGS="-Os -W -Wall" ./configure --prefix=/usr --host=${CLFS_TARGET} --enable-static --with-zlib=/home/clfs/linuxfromscratch-sources/zlib-1.2.11/
make MULTI=1   PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" -j$CPUTHREAD
make MULTI=1   PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"  install DESTDIR=${CLFS}/targetfs
install -dv ${CLFS}/targetfs/etc/dropbear
cd /home/clfs/linuxfromscratch-sources/cross-lfs-bootscripts-embedded
make install-dropbear DESTDIR=${CLFS}/targetfs
}

function wirelesstools(){
cd /home/clfs/linuxfromscratch-sources/wireless_tools.29
sed -i s/gcc/\$\{CLFS\_TARGET\}\-gcc/g Makefile
sed -i s/\ ar/\ \$\{CLFS\_TARGET\}\-ar/g Makefile
sed -i s/ranlib/\$\{CLFS\_TARGET\}\-ranlib/g Makefile
make PREFIX=${CLFS}/targetfs/usr -j$CPUTHREAD
make install PREFIX=${CLFS}/targetfs/usr
}

function netplug(){
cd /home/clfs/linuxfromscratch-sources/netplug-1.2.9.2
patch -Np1 -i ../netplug-1.2.9.2-fixes-1.patch
make -j$CPUTHREAD
make DESTDIR=${CLFS}/targetfs install
}

function zlib(){
cd /home/clfs/linuxfromscratch-sources/zlib
git checkout $ZLIB_TAG
CC=$CC CFLAGS="-Os" ./configure --shared
make
make prefix=${CLFS}/cross-tools/${CLFS_TARGET} install
cp -v ${CLFS}/cross-tools/${CLFS_TARGET}/lib/libz.so.1.2.11 ${CLFS}/targetfs/lib/
ln -sv libz.so.1.2.11 ${CLFS}/targetfs/lib/libz.so.1
}

function os-release(){
cat << EOF > ${CLFS}/targetfs/etc/os-release
NAME="BlackOS Linux"
PRETTY_NAME="BlackOS Linux"
ID=blackos
BUILD_ID=release
HOME_URL="https://www.shyanjmc.com"
EOF
}

function ownership_tarball(){
su -c "chown -Rv root:root ${CLFS}/targetfs"
su -c "chgrp -v 13 ${CLFS}/targetfs/var/log/lastlog"
install -dv ${CLFS}/build
cd ${CLFS}/targetfs
su -c "tar -czfv ${CLFS}/build/blackos-automated.tar.bz2 * && chown clfs:clfs ${CLFS}/build/*"
}

#####################################################
##################### Def Zone ######################
#####################################################

curl https://raw.githubusercontent.com/ShyanJMC/BlackOS/main/bashrc > blackosrc
source blackosrc

#####################################################
##################### Exec zone #####################
#####################################################
create_folders
link_mtab
create_root
libgcc_s_so_1
musl
busybox
ianaetc
fstab
linux
cross_scripts
mdev
bprofile
inittab
hostname
hostfile
networkinterfaces
zlib
dropbear
wirelesstools
netplug
ownership_tarball
