#!/bin/bash
# Maintainer;	ShyanJMC (Joaquin Manuel Crespo)
# Autor:	ShyanJMC (Joaquin Manuel Crespo)
# Email:	joaquincrespo96@gmail.com
# Email:	shyanjmc@protonmail.com
# Email:	shyan@shyanjmc.com
# Copyright; 	2021(c)

################################################
############## Variables zone ##################
################################################

export CLFS=/targetfs
export CPUTHREAD=$(cat /proc/cpuinfo | grep processor | wc | cut -d' ' -f7)
export DROPBEAR_TAG=tag/DROPBEAR_2020.81
export ZLIB_TAG=tags/v1.2.11
export WORK_DIR=/linuxfromscratch-sources
export BUILD_DIR=/build
export EUDEV_TAG=tags/v3.2.10
export OPENRC_BRACH=remotes/origin/HEAD
export NUSHELL_BRACH=main
export CROSS_TOOLS=/crosstools
export COREUTILS_TAG=tags/v8.32
export QEMU_LD_PREFIX="/usr/aarch64-linux-gnu/"

###########################################################################
######################## Functions zone ###################################
###########################################################################

function prebuild(){
	mkdir -p /crosstools/lib
	pacman -Syuq --needed --noconfirm base-devel rustup git tar zip unzip gzip zlib qemu qemu-arch-extra qemu extra/qemu-arch-extra openssl core/linux-aarch64-headers core/linux-api-headers core/linux-raspberrypi4-headers core/linux-odroid-n2-headers core/linux-odroid-c2-headers core/linux-oak-headers core/linux-gru-headers core/linux-espressobin-headers core/gcc-libs 
	git clone https://github.com/ShyanJMC/LinuxFromScratch-Sources -C ${WORK_DIR}
	cd ${WORK_DIR}/
	git submodule init && git submodule sync && git submodule update --recursive
}


function create_folders(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating directories"
	mkdir -pv ${CLFS}/{boot,dev,etc,home,}
	mkdir -pv ${CLFS}/{mnt,opt,proc,srv,sys}
	mkdir -pv ${CLFS}/var/{cache,lib,local,lock,log,opt,spool}
	install -dv -m 0750 ${CLFS}/root
	install -dv -m 1777 ${CLFS}/{var/,}tmp
	mkdir -pv ${CLFS}/usr/{,local/}{bin,include,lib,sbin,share,src}
	ln -s usr/lib ${CLFS}/lib
	ln -s usr/bin ${CLFS}/bin
	ln -s usr/sbin ${CLFS}/sbin
	ln -s ../run ${CLFS}/var/run
	ln -s ../run/lock ${CLFS}/var/lock
	ln -s spool/mail ${CLFS}/var/mail
	mkdir -pv ${CLFS}/lib/{firmware,modules}
	touch ${CLFS}/var/log/lastlog
	echo -e "===============================================\n==============================================="
}

function link_mtab(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating symbolinc links."
	ln -svf ../proc/mounts ${CLFS}/etc/mtab
}

function create_root(){ 
	echo -e "===============================================\n==============================================="
	echo "Creating passwd file."
	cat > ${CLFS}/etc/passwd << "EOF"
root::0:0:root:/root:/bin/ash
EOF
	echo -e "===============================================\n==============================================="
}

function libgcc_s_so_1(){
	echo -e "===============================================\n==============================================="
	echo -e "Coping libgcc_s.so.{,1} lib64 file."
	cp -v /lib/libgcc_s.so ${CLFS}/lib/libgcc_s.so
	cp -v /lib/libgcc_s.so.1 ${CLFS}/lib/libgcc_s.so.1
}

function sync_repo(){
	echo -e "===============================================\n==============================================="
	echo -e "Sync repositories."
	cd ${WORK_DIR}
	git submodule init
	git submodule sync
	git submodule update --recursive
}

function musl(){
	echo -e "===============================================\n==============================================="
	echo -e "Compiling musl."
	mkdir ${WORK_DIR}/musl/build
	cd ${WORK_DIR}/musl/build
	../configure --prefix=/ --disable-static
	make -j$CPUTHREAD
	DESTDIR=${CLFS}/ make install-libs
}

function coreutils(){
	echo "Compiling coreutils"
	cd ${WORK_DIR}/coreutils
	git checkout ${COREUTILS_TAG}
	make clean
	./configure --with-openssl --libexecdir=/usr/lib --prefix=${CLFS} 
	make -j$CPUTHREAD
}



function eudev(){
	cd ${WORK_DIR}/eudev
	git checkout $EUDEV_TAG
	autoreconf -f -i -s
	./configure --prefix=/targetfs/ --disable-selinux --enable-introspection=yes --enable-hwdb
	# As BlackOS have al bin directories as links to /usr/bin, the below line change the force of creation of symlink to avoid issues.
	sed -i '1209d' src/udev/Makefile
	sed -i '1208s/||//' src/udev/Makefile
	make -j$CPUTHREAD
	make install
}

function openrc(){
	cd ${WORK_DIR}/openrc
	git checkout ${OPENRC_BRACH}
	DESDIT=${CLFS} make PROGLDFLAGS=-static LIBNAME=lib64 MKNET=no MKPREFIX=yes MKSELINUX=no MKSYSVINIT=yes \
BRANDING=\"BlackOS\" PKG_PREFIX=${CLFS}/usr/pkg LOCAL_PREFIX=${CLFS}/usr/local \
PREFIX=${CLFS} -j$CPUTHREAD
	DESDIT=${CLFS} make PROGLDFLAGS=-static LIBNAME=lib64 MKNET=no MKPREFIX=yes MKSELINUX=no MKSYSVINIT=yes \
BRANDING=\"BlackOS\" PKG_PREFIX=${CLFS}/usr/pkg LOCAL_PREFIX=${CLFS}/usr/local \
PREFIX=${CLFS} install 

	echo -e "Re writing some symlinks to avoid issues."
	rm ${CLFS}/usr/bin/{rc-sstat,reboot,poweroff,shutdown,halt}
	ln -s ../libexec/rc/bin/rc-sstat ${CLFS}/usr/bin/rc-sstat
	ln -s ../libexec/rc/bin/halt ${CLFS}/usr/bin/halt
	ln -s ../libexec/rc/bin/poweroff ${CLFS}/usr/bin/poweroff
	ln -s ../libexec/rc/bin/reboot ${CLFS}/usr/bin/reboot
	ln -s ../libexec/rc/bin/shutdown ${CLFS}/usr/bin/shutdown
}

function openrc_scripts(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating OpenRC init.d files for udhcpc and login."
cat > ${CLFS}/etc/init.d/login << EOF
command=/usr/bin/login
name="Login program."
EOF
}

function eudev_openrc_scripts(){
	echo -e "===============================================\n==============================================="
        echo -e "Creating OpenRC init.d files for udev."
	cd ${WORK_DIR}/udev-gentoo-scripts
	# Add text to the first line
	sed -i '1 i\DESTDIR=${CLFS}/' Makefile
	make install
}

function ianaetc(){
	echo -e "===============================================\n==============================================="
	echo -e "Compiling ianaetc."
	cd ${WORK_DIR}/iana-etc-2.30
	patch -Np1 -i ../iana-etc-2.30-update-2.patch
	make get
	make STRIP=yes
	make DESTDIR=${CLFS} install
}

function fstab(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating empty fstab."
	cat > ${CLFS}/etc/fstab << "EOF"
# file-system  mount-point  type   options          dump  fsck
EOF
}

function bprofile(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating etc profile file."
	cat > ${CLFS}/etc/profile << "EOF"
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


function hostname(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating hostname."
	echo "blackos" > ${CLFS}/etc/HOSTNAME
}

function hostfile(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating hosts file."
	cat > ${CLFS}/etc/hosts << "EOF"
# Begin /etc/hosts (network card version)

127.0.0.1 localhost blackos

# End /etc/hosts (network card version)
EOF
}

function networkinterfaces(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating and configuring network scripts."
	mkdir -pv ${CLFS}/etc/network/if-{post-{up,down},pre-{up,down},up,down}.d
	mkdir -pv ${CLFS}/usr/share/udhcpc
	cat > ${CLFS}/etc/network/interfaces << "EOF"
auto eth0
iface eth0 inet dhcp
EOF

	cat > ${CLFS}/usr/share/udhcpc/default.script << "EOF"
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

	chmod +x ${CLFS}/usr/share/udhcpc/default.script
}

function dropbear(){
	echo -e "===============================================\n==============================================="
	echo -e "Compiling DropBear SSH."
	cd ${WORK_DIR}/dropbear
	git checkout $DROPBEAR_TAG
	sed -i 's/.*mandir.*//g' Makefile.in
	CC=$CC CFLAGS="-Os -W -Wall" ./configure --prefix=/usr --enable-static --with-zlib=${WORK_DIR}/zlib
	make MULTI=1   PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" -j$CPUTHREAD
	make MULTI=1   PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"  install DESTDIR=${CLFS}/targetfs
	install -dv ${CLFS}/etc/dropbear
	cd ${WORK_DIR}/cross-lfs-bootscripts-embedded
	make install-dropbear DESTDIR=${CLFS}/
}

function wirelesstools(){
	echo -e "===============================================\n==============================================="
	echo -e "Compiling wirelesstools."
	cd /home/clfs/linuxfromscratch-sources/wireless_tools.29
	sed -i s/gcc/\$\{CLFS\_TARGET\}\-gcc/g Makefile
	sed -i s/\ ar/\ \$\{CLFS\_TARGET\}\-ar/g Makefile
	sed -i s/ranlib/\$\{CLFS\_TARGET\}\-ranlib/g Makefile
	make PREFIX=${CLFS}/usr -j$CPUTHREAD
	make install PREFIX=${CLFS}/usr
}

function netplug(){
	echo -e "===============================================\n==============================================="
	echo -e "Compiling netplug."
	cd /home/clfs/linuxfromscratch-sources/netplug-1.2.9.2
	patch -Np1 -i ../netplug-1.2.9.2-fixes-1.patch
	make -j$CPUTHREAD
	make DESTDIR=${CLFS} install
}

function zlib(){
	echo -e "===============================================\n==============================================="
	echo -e "Compiling zlib."
	cd ${WORK_DIR}/zlib
	git checkout $ZLIB_TAG
	CC=$CC CFLAGS="-Os" ./configure --shared
	make
	make prefix=/crosstools/ install
	cp -v /crosstools/lib/libz.so.1.2.11 ${CLFS}/lib/
	ln -sv libz.so.1.2.11 ${CLFS}/lib/libz.so.1
}

function os-release(){
	echo -e "===============================================\n==============================================="
	echo -e "Creating os-release file."
	cat << EOF > ${CLFS}/etc/os-release
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
	su -c "chown -Rv root:root ${CLFS}/"
	su -c "chgrp -v 13 ${CLFS}/var/log/lastlog"
	install -dv /build
	cd ${CLFS}
	tar -czfv /build/blackos-automated.tar.gz *
}

#####################################################
##################### Def Zone ######################
#####################################################

#####################################################
##################### Exec zone #####################
#####################################################
prebuild
create_folders
link_mtab
create_root
libgcc_s_so_1
sync_repo
musl
coreutils
eudev
openrc
openrc_scripts
eudev_openrc_scripts
ianaetc
fstab
bprofile
hostname
hostfile
networkinterfaces
dropbear
wirelesstools
netplug
zlib
os-release
ownership_tarball
