#######################################
## 5.36. Changing Ownership 
#######################################
start_timer "5.36. Changing Ownership"

export LFS=/mnt/lfs
chown -R root:root $LFS/tools

end_timer

#######################################
## 6.2. Preparing Virtual Kernel File Systems 
#######################################
start_timer "6.2. Preparing Virtual Kernel File Systems"

mkdir -pv $LFS/{dev,proc,sys,run}

mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3

mount -v --bind /dev $LFS/dev

mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

end_timer

#######################################
## 6.4. Entering the Chroot Environment 
#######################################
start_timer "6.4. Entering the Chroot Environment"

chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h

mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -v  /usr/libexec
mkdir -pv /usr/{,local/}share/man/man{1..8}

case $(uname -m) in
 x86_64) mkdir -v /lib64 ;;
esac

mkdir -v /var/{log,mail,spool}
ln -sv /run /var/run
ln -sv /run/lock /var/lock
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}

#######################################
## Helper functions
#######################################
function go_to_sources() {
    cd "$LFS/sources"
}

function tar_cd() {
    if [ -n "$3" ]; then
        last_package="$3"
    else
        last_package="$1"
    fi
    go_to_sources
    tar xf "$1.$2"
    cd $last_package
}

function rm_cd() {
    if [ -n "$last_package" ]; then
        go_to_sources
        rm -rf "$last_package"
    fi
}

log_file=/tmp/build.log

function build_log() {
    echo "$(formated_date) ($(whoami)) $1" >> $log_file
}

function pad() {
    [ $1 -gt 9 ] && echo $1 || echo "0"$1
}

function format_time() {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi

    sec=$(pad $sec)
    min=$(pad $min)
    hour=$(pad $hour)
    day=$(pad $day)
    echo "$day"d"$hour"h"$min"m"$sec"s
}

function formated_date() {
    echo $(date +%FT%H:%M:%S)
}

function start_timer() {
    start_time=$SECONDS
    timer_title="$1"
    build_log "($(format_time $start_time)) S $timer_title"
}

function end_timer() {
    if [ -n "$timer_title" ]; then
        end_time=$SECONDS
        elapsed="$(($end_time-$start_time))"
        build_log "($(format_time $elapsed)) F $timer_title"
        timer_title=""
    fi
}

function start_package() {
    start_timer "$1"
    tar_cd $2 $3 $4
}

function end_package() {
    rm_cd
    end_timer
}

#######################################
## 6.6. Creating Essential Files and Symlinks 
#######################################
start_timer "6.6. Creating Essential Files and Symlinks"

ln -sv /tools/bin/{bash,cat,dd,echo,ln,pwd,rm,stty} /bin
ln -sv /tools/bin/{env,install,perl} /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -sv /tools/lib/libstdc++.{a,so{,.6}} /usr/lib
for lib in blkid lzma mount uuid
do
    ln -sv /tools/lib/lib$lib.so* /usr/lib
done
ln -svf /tools/include/blkid    /usr/include
ln -svf /tools/include/libmount /usr/include
ln -svf /tools/include/uuid     /usr/include
install -vdm755 /usr/lib/pkgconfig
for pc in blkid mount uuid
do
    sed 's@tools@usr@g' /tools/lib/pkgconfig/${pc}.pc \
        > /usr/lib/pkgconfig/${pc}.pc
done
ln -sv bash /bin/sh

ln -sv /proc/self/mounts /etc/mtab

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
nogroup:x:99:
users:x:999:
EOF

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

end_timer

exec /tools/bin/bash --login +h

KERNEL=$(uname -r | cut -d"." -f1.2)

#######################################
## 6.7. Linux-4.18.5 API Headers 
#######################################
unset LFS

start_package "6.7. Linux-4.18.5 API Headers" linux-4.18.5 tar.xz

make mrproper

make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include

end_package

#######################################
## 6.8. Man-pages-4.16 
#######################################
start_package "6.8. Man-pages-4.16" man-pages-4.16 tar.xz

make install

end_package

#######################################
## 6.9. Glibc-2.28 
#######################################
KERNEL=$(uname -r | cut -d"." -f1,2)
start_package "6.9. Glibc-2.28 make" glibc-2.28 tar.xz

patch -Np1 -i ../glibc-2.28-fhs-1.patch

ln -sfv /tools/lib/gcc /usr/lib

case $(uname -m) in
    i?86)    GCC_INCDIR=/usr/lib/gcc/$(uname -m)-pc-linux-gnu/8.2.0/include
            ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
    ;;
    x86_64) GCC_INCDIR=/usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/include
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
    ;;
esac

rm -f /usr/include/limits.h

mkdir -v build
cd       build

CC="gcc -isystem $GCC_INCDIR -isystem /usr/include" \
../configure --prefix=/usr                          \
             --disable-werror                       \
             --enable-kernel=$KERNEL                \
             --enable-stack-protector=strong        \
             libc_cv_slibdir=/lib
unset GCC_INCDIR

make

start_timer "6.9. Glibc-2.28 make install"

touch /etc/ld.so.conf

sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

make install

end_package
start_timer "Glibc Configure Time Zones"

cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

mkdir -pv /usr/lib/locale
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030

make localedata/install-locales

end_timer

#######################################
## 6.9.2. Configuring Glibc 
#######################################
start_timer "6.9.2. Configuring Glibc"

cd /sources/glibc-2.28

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../../tzdata2018e.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p Europe/Dublin
unset ZONEINFO

cp -v /usr/share/zoneinfo/Europe/Dublin /etc/localtime

#######################################
## 6.9.2.3. Configuring the Dynamic Loader 
#######################################
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

#######################################
## 6.10. Adjusting the Toolchain 
#######################################
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld

gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs

end_timer

#######################################
## 6.11. Zlib-1.2.11 
#######################################
start_package "6.11. Zlib-1.2.11 make" zlib-1.2.11 tar.xz

./configure --prefix=/usr
make
make install

mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so

end_package

#######################################
## 6.12. File-5.34 
#######################################
start_package "6.12. File-5.34 make" file-5.34 tar.gz
cd file-5.34

./configure --prefix=/usr
make

make install

end_package

#######################################
## 6.13. Readline-7.0 
#######################################
start_package "6.13. Readline-7.0" readline-7.0 tar.gz

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/readline-7.0

make SHLIB_LIBS="-L/tools/lib -lncursesw"

make SHLIB_LIBS="-L/tools/lib -lncurses" install

mv -v /usr/lib/lib{readline,history}.so.* /lib
chmod -v u+w /lib/lib{readline,history}.so.*
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so

install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-7.0

end_package

#######################################
## 6.14. M4-1.4.18 
#######################################
start_package "6.14. M4-1.4.18 make" m4-1.4.18 tar.xz

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/usr

make

make install

end_package

#######################################
## 6.15. Bc-1.07.1 
#######################################
start_package "6.15. Bc-1.07.1 make" bc-1.07.1 tar.gz

cat > bc/fix-libmath_h << "EOF"
#! /bin/bash
sed -e '1   s/^/{"/' \
    -e     's/$/",/' \
    -e '2,$ s/^/"/'  \
    -e   '$ d'       \
    -i libmath.h

sed -e '$ s/$/0}/' \
    -i libmath.h
EOF

ln -sv /tools/lib/libncursesw.so.6 /usr/lib/libncursesw.so.6
ln -sfv libncurses.so.6 /usr/lib/libncurses.so

sed -i -e '/flex/s/as_fn_error/: ;; # &/' configure

./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info
            
make

make install

end_package

#######################################
## 6.16. Binutils-2.31.1 
#######################################
start_package "6.16. Binutils-2.31.1 make" binutils-2.31.1 tar.xz

mkdir -v build
cd       build



../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib

make tooldir=/usr

make tooldir=/usr install

end_package

#######################################
## 6.17. GMP-6.1.2 
#######################################
start_package "6.17. GMP-6.1.2 make" gmp-6.1.2 tar.xz

#
#---
#Optional for cross-compiling
#
#cp -v configfsf.guess config.guess
#cp -v configfsf.sub   config.sub
#
#---
#

./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.1.2

make
make html

make install
make install-html

end_package

#######################################
## 6.18. MPFR-4.0.1 
#######################################
start_package "6.18. MPFR-4.0.1 make" mpfr-4.0.1 tar.xz

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.0.1

make
make html

make install
make install-html

end_package

#######################################
## 6.19. MPC-1.1.0 
#######################################
start_package "6.19. MPC-1.1.0 make" mpc-1.1.0 tar.gz

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.1.0

make
make html

make install
make install-html

end_package

#######################################
## 6.20. Shadow-4.6 
#######################################
start_package "6.20. Shadow-4.6" shadow-4.6 tar.xz

sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs

sed -i 's/1000/999/' etc/useradd

./configure --sysconfdir=/etc --with-group-name-max-length=32

make
make install

mv -v /usr/bin/passwd /bin

end_package


#######################################
## 6.20.2. Configuring Shadow 
#######################################
pwconv
grpconv
passwd root
