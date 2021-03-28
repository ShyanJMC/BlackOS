#!/bin/bash
# Maintainer;	ShyanJMC (Joaquin Manuel Crespo)
# Autor:	ShyanJMC (Joaquin Manuel Crespo)
# Email:	joaquincrespo96@gmail.com
# Copyright; 	2021(c)

################################################
############## Variables zone ##################
################################################

export CPUTHREAD=$(cat /proc/cpuinfo | grep processor | wc | cut -d' ' -f7)
export BUSYBOX_BRANCH=remotes/origin/1_32_stable
export DROPBEAR_TAG=tag/DROPBEAR_2020.81
export ZLIB_TAG=tags/v1.2.11
export WORK_DIR=/home/clfs/linuxfromscratch-sources/
export EUDEV_TAG=tags/v3.2.10
export OPENRC_BRACH=remotes/origin/HEAD

###########################################################################
######################## Functions zone ###################################
###########################################################################

function create_folders(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating directories"
	mkdir -pv ${CLFS}/targetfs/{boot,dev,etc,home,}
	mkdir -pv ${CLFS}/targetfs/{mnt,opt,proc,srv,sys}
	mkdir -pv ${CLFS}/targetfs/var/{cache,lib,local,lock,log,opt,spool}
	install -dv -m 0750 ${CLFS}/targetfs/root
	install -dv -m 1777 ${CLFS}/targetfs/{var/,}tmp
	mkdir -pv ${CLFS}/targetfs/usr/{,local/}{bin,include,lib,sbin,share,src}
	ln -s usr/lib ${CLFS}/targetfs/lib
	ln -s usr/lib ${CLFS}/targetfs/lib64
	ln -s usr/bin ${CLFS}/targetfs/bin
	ln -s usr/bin ${CLFS}/targetfs/sbin
	ln -s ../run ${CLFS}/targetfs/var/run
	ln -s ../run/lock ${CLFS}/targetfs/var/lock
	ln -s spool/mail ${CLFS}/targetfs/var/mail
	ln -s lib ${CLFS}/targetfs/usr/lib64
	mkdir -pv ${CLFS}/targetfs/lib/{firmware,modules}
	touch ${CLFS}/targetfs/var/log/lastlog
	echo -e "===============================================\n==============================================="
}

function link_mtab(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating symbolinc links."
	ln -svf ../proc/mounts ${CLFS}/targetfs/etc/mtab
}

function create_root(){ 
	echo -e "===============================================\n==============================================="
	echo "Creating passwd file."
	cat > ${CLFS}/targetfs/etc/passwd << "EOF"
root::0:0:root:/root:/bin/ash
EOF
	echo -e "===============================================\n==============================================="
}

function libgcc_s_so_1(){
	echo -e "===============================================\n==============================================="
	echo -e "Coping libgcc_s.so.1 lib64 file."
	cp -v /usr/aarch64-linux-gnu/lib64/libgcc_s.so.1 ${CLFS}/targetfs/lib/libgcc_s.so.1
	# ${CLFS_TARGET}-strip ${CLFS}/targetfs/lib/libgcc_s.so.1
}

function musl(){
	echo -e "===============================================\n==============================================="
	echo -e "Compiling musl."
	mkdir ${WORK_DIR}/musl/build
	cd ${WORK_DIR}/musl/build
	../configure CROSS_COMPILE=${CLFS_TARGET}- --prefix=/ --disable-static --target=${CLFS_TARGET}
	make -j$CPUTHREAD
	DESTDIR=${CLFS}/targetfs/ make install-libs
}

function busybox(){
	echo -e "===============================================\n==============================================="
	echo -e "Compiling busybox."
	cd ${WORK_DIR}/busybox
	git checkout $BUSYBOX_BRANCH
	# Check if ".config" file exist
	if [ ! -f ".config"  ]; then
		# If not exist, execute
		make distclean
		make ARCH=aarch64 defconfig
	fi
	make ARCH=aarch64 menuconfig
	#sed -i 's/\(CONFIG_\)\(.*\)\(INETD\)\(.*\)=y/# \1\2\3\4 is not set/g' .config
	#sed -i 's/\(CONFIG_IFPLUGD\)=y/# \1 is not set/' .config
	#sed -i 's/\(CONFIG_FEATURE_WTMP\)=y/# \1 is not set/' .config
	#sed -i 's/\(CONFIG_FEATURE_UTMP\)=y/# \1 is not set/' .config
	#sed -i 's/\(CONFIG_UDPSVD\)=y/# \1 is not set/' .config
	#sed -i 's/\(CONFIG_TCPSVD\)=y/# \1 is not set/' .config
	make ARCH="${CLFS_ARCH}" CROSS_COMPIlE="${CLFS_TARGET}-" -j$CPUTHREAD
	make ARCH="${CLFS_ARCH}" CROSS_COMPILE="${CLFS_TARGET}-" CONFIG_PREFIX="${CLFS}/targetfs" install
}

function eudev(){
	cd ${WORK_DIR}/eudev
	git checkout $EUDEV_TAG
	autoreconf -f -i -s
	./configure --host=aarch64-unknown-linux-gnu --prefix=/home/clfs/BlackOS/targetfs/ --disable-manpages \
 --disable-selinux --enable-introspection=yes --with-sysroot=/usr/aarch64-linux-gnu
	make -j4
	make install
}

function openrc(){
	cd ${WORK_DIR}/openrc
	git checkout ${OPENRC_BRACH}
	DESDIT=/home/clfs/BlackOS/targetfs make PROGLDFLAGS=-static LIBNAME=lib64 MKNET=no MKPREFIX=yes MKSELINUX=no MKSYSVINIT=yes \
BRANDING=\"BlackOS\" PKG_PREFIX=/home/clfs/BlackOS/targetfs/usr/pkg LOCAL_PREFIX=/home/clfs/BlackOS/targetfs/usr/local \
PREFIX=/home/clfs/BlackOS/targetfs
	DESDIT=/home/clfs/BlackOS/targetfs make PROGLDFLAGS=-static LIBNAME=lib64 MKNET=no MKPREFIX=yes MKSELINUX=no MKSYSVINIT=yes \
BRANDING=\"BlackOS\" PKG_PREFIX=/home/clfs/BlackOS/targetfs/usr/pkg LOCAL_PREFIX=/home/clfs/BlackOS/targetfs/usr/local \
PREFIX=/home/clfs/BlackOS/targetfs install 

}

function openrc_scripts(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating OpenRC init.d files for udev, udhcpc and login."
	cat > ${CLFS}/targetfs/etc/init.d/eudev << "EOF"
#!@RUNSCRIPT@
# Copyright 1999-2010 Gentoo Fundation
# Distributed under the terms of GNU General Public License v2

command=/usr/bin/udevd
description="eudev from Gentoo. Udev for friends. Udev manages device permissions and symbolic links in /dev"
extra_started_commands="reload"
description_reload="Reload the udev rules and databases"
rc_coldplug=${rc_coldplug:-${RC_COLDPLUG:-YES}}
udev_debug="${udev_debug:-no}"
udev_monitor="${udev_monitor:-no}"
udev_monitor_keep_running="${udev_monitor_keep_running:-no}"
udev_settle_timeout="${udev_settle_timeout:-60}"
kv_min="${kv_min:-2.6.34}"

depend()
{
    # we depend on udev-mount explicitly, not dev-mount generic as we don't
    # want mdev as a dev-mount provider to come in.
    provide dev
    need sysfs udev-mount
    before checkfs fsck

    # udev does not work inside vservers
    keyword -vserver -lxc
}

KV_to_int()
{
    [ -z $1 ] && return 1

    local x=${1%%[!0-9.]*} y= z=
    local KV_MAJOR=${x%%.*}
    y=${x#*.}
    [ "$x" = "$y" ] && y=0.0
    local KV_MINOR=${y%%.*}
    z=${y#*.}
    [ "$y" = "$z" ] && z=0
    local KV_MICRO=${z%%.*}
    local KV_int=$((${KV_MAJOR} * 65536 + ${KV_MINOR} * 256 + ${KV_MICRO} ))

    # We make version 2.2.0 the minimum version we will handle as
    # a sanity check ... if its less, we fail ...
    [ "${KV_int}" -lt 131584 ] && return 1

    echo "${KV_int}"
}

_RC_GET_KV_CACHE=""
get_KV()
{
    if [ -z "${_RC_GET_KV_CACHE}" ] ; then
        _RC_GET_KV_CACHE="$(uname -r)"
    fi
    echo "$(KV_to_int "${_RC_GET_KV_CACHE}")"
    return $?
}

# FIXME
# Instead of this script testing kernel version, udev itself should
# Maybe something like udevd --test || exit $?
check_kernel()
{
    if [ $(get_KV) -lt $(KV_to_int ${kv_min}) ]; then
        eerror "Your kernel is too old to work with this version of udev."
        eerror "Current udev only supports Linux kernel ${kv_min} and newer."
        return 1
    fi
    return 0
}

start_pre()
{
    check_kernel || return 1
    if [ -e /proc/sys/kernel/hotplug ]; then
        echo "" >/proc/sys/kernel/hotplug
    fi

    # load unix domain sockets if built as module, Bug #221253
    # and not yet loaded, Bug #363549
    if [ ! -e /proc/net/unix ]; then
        if ! modprobe unix; then
            eerror "Cannot load the unix domain socket module"
        fi
    fi

    if yesno "${udev_debug}"; then
        command_args="${command_args} --debug 2> /run/udevdebug.log"
    fi
}

is_service_enabled()
{
    local svc="$1"

    [ ! -e "/etc/init.d/${svc}" ] && return 1

    [ -e "/etc/runlevels/${RC_BOOTLEVEL}/${svc}" ] && return 0
    [ -e "/etc/runlevels/${RC_DEFAULTLEVEL}/${svc}" ] && return 0
    return 1
}

disable_oldnet_hotplug()
{
    if is_service_enabled network; then
        # disable network hotplugging
        local f="/run/udev/rules.d/90-network.rules"
        echo "# This file disables network hotplug events calling" >> "${f}"
        echo "# old-style openrc net scripts" >> "${f}"
        echo "# as we use /etc/init.d/network to set up our network" >> "${f}"
    fi
}

start_udevmonitor()
{
    yesno "${udev_monitor}" || return 0

    udevmonitor_log=/run/udevmonitor.log
    udevmonitor_pid=/run/udevmonitor.pid

    einfo "udev: Running udevadm monitor ${udev_monitor_opts} to log all events"
    start-stop-daemon --start --stdout "${udevmonitor_log}" \
        --make-pidfile --pidfile "${udevmonitor_pid}" \
        --background --exec /sbin/udevadm -- monitor ${udev_monitor_opts}
}

populate_dev()
{
    if get_bootparam "nocoldplug" ; then
        rc_coldplug="NO"
        ewarn "Skipping udev coldplug as requested in kernel cmdline"
    fi

    ebegin "Populating /dev with existing devices through uevents"
    if ! yesno "${rc_coldplug}"; then
        # Do not run any init-scripts, Bug #206518
        udevadm control --property=do_not_run_plug_service=1
    fi
    udevadm trigger --type=subsystems --action=add
    udevadm trigger --type=devices --action=add
    eend $?
    ebegin "Waiting for uevents to be processed"
    udevadm settle --timeout=${udev_settle_timeout}
    eend $?
    udevadm control --property=do_not_run_plug_service=
    return 0
}

stop_udevmonitor()
{
    yesno "${udev_monitor}" || return 0

    if yesno "${udev_monitor_keep_running}"; then
        ewarn "udev: udevmonitor is still running and writing into ${udevmonitor_log}"
    else
        einfo "udev: Stopping udevmonitor: Log is in ${udevmonitor_log}"
        start-stop-daemon --stop --pidfile "${udevmonitor_pid}" --exec /sbin/udevadm
    fi
}

display_hotplugged_services()
{
    local svcfile= svc= services=
    for svcfile in "${RC_SVCDIR}"/hotplugged/*; do
        svc="${svcfile##*/}"
        [ -x "${svcfile}" ] || continue

        services="${services} ${svc}"
    done
    [ -n "${services}" ] && einfo "Device initiated services:${HILITE}${services}${NORMAL}"
}

start_post()
{
    disable_oldnet_hotplug
    start_udevmonitor
    populate_dev
    stop_udevmonitor
    display_hotplugged_services
    return 0
}

reload()
{
    ebegin "reloading udev rules and databases"
    udevadm control --reload
    eend $?
}
EOF

cat > ${CLFS}/targetfs/etc/init.d/udhcpc << EOF
command=/usr/bin/udhcpc
pidfile=/var/run/udhcpc.pid
name="UDHCPC an DHCP Client Daemon"
EOF

cat > ${CLFS}/targetfs/etc/init.d/login << EOF
command=/usr/bin/login
name="Login program."
EOF
}

function ianaetc(){
	echo -e "===============================================\n==============================================="
	echo -e "Compiling ianaetc."
	cd ${WORK_DIR}/iana-etc-2.30
	patch -Np1 -i ../iana-etc-2.30-update-2.patch
	make get
	make STRIP=yes
	make DESTDIR=${CLFS}/targetfs install
}

function fstab(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating empty fstab."
	cat > ${CLFS}/targetfs/etc/fstab << "EOF"
# file-system  mount-point  type   options          dump  fsck
EOF
}

#function cross_scripts(){
#	echo -e "===============================================\n==============================================="
#	echo -e "Installing cross_cripts from CLFS."
#	cd /home/clfs/linuxfromscratch-sources/cross-lfs-bootscripts-embedded
#	make DESTDIR=${CLFS}/targetfs install-bootscripts
#}

function mdev(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating mdev.conf file."
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
	echo -e "===============================================\n==============================================="
	echo -e "Creating etc profile file."
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
	echo -e "===============================================\n==============================================="
	echo -e "Creating etc inittab file."
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
	echo -e "===============================================\n==============================================="
	echo -e "Creating hostname."
	echo "blackos" > ${CLFS}/targetfs/etc/HOSTNAME
}

function hostfile(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating hosts file."
	cat > ${CLFS}/targetfs/etc/hosts << "EOF"
# Begin /etc/hosts (network card version)

127.0.0.1 localhost blackos

# End /etc/hosts (network card version)
EOF
}

function networkinterfaces(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating and configuring network scripts."
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
	echo -e "===============================================\n==============================================="
	echo -e "Compiling DropBear SSH."
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
	echo -e "===============================================\n==============================================="
	echo -e "Compiling wirelesstools."
	cd /home/clfs/linuxfromscratch-sources/wireless_tools.29
	sed -i s/gcc/\$\{CLFS\_TARGET\}\-gcc/g Makefile
	sed -i s/\ ar/\ \$\{CLFS\_TARGET\}\-ar/g Makefile
	sed -i s/ranlib/\$\{CLFS\_TARGET\}\-ranlib/g Makefile
	make PREFIX=${CLFS}/targetfs/usr -j$CPUTHREAD
	make install PREFIX=${CLFS}/targetfs/usr
}

function netplug(){
	echo -e "===============================================\n==============================================="
	echo -e "Compiling netplug."
	cd /home/clfs/linuxfromscratch-sources/netplug-1.2.9.2
	patch -Np1 -i ../netplug-1.2.9.2-fixes-1.patch
	make -j$CPUTHREAD
	make DESTDIR=${CLFS}/targetfs install
}

function zlib(){
	echo -e "===============================================\n==============================================="
	echo -e "Compiling zlib."
	cd /home/clfs/linuxfromscratch-sources/zlib
	git checkout $ZLIB_TAG
	CC=$CC CFLAGS="-Os" ./configure --shared
	make
	make prefix=${CLFS}/cross-tools/${CLFS_TARGET} install
	cp -v ${CLFS}/cross-tools/${CLFS_TARGET}/lib/libz.so.1.2.11 ${CLFS}/targetfs/lib/
	ln -sv libz.so.1.2.11 ${CLFS}/targetfs/lib/libz.so.1
}

function os-release(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating os-release file."
	cat << EOF > ${CLFS}/targetfs/etc/os-release
NAME="BlackOS Linux"
PRETTY_NAME="BlackOS Linux"
ID=blackos
BUILD_ID=release
HOME_URL="https://www.shyanjmc.com"
EOF
}

function ownership_tarball(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating tarball."
	su -c "chown -Rv root:root ${CLFS}/targetfs"
	su -c "chgrp -v 13 ${CLFS}/targetfs/var/log/lastlog"
	install -dv ${CLFS}/build
	cd ${CLFS}/targetfs
	su -c "tar -czfv ${CLFS}/build/blackos-automated.tar.gz * && chown clfs:clfs ${CLFS}/build/*"
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
eudev
openrc
openrc_scripts
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
os-release
ownership_tarball
