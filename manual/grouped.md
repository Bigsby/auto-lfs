# All grouped scripts
```
sudo passwd root

```
---
```
su -

```
---
```
export DRIVE=sdb
export PARTITION_NUMBER=1

cat >>  /etc/bash.bashrc << EOF
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
EOF

```
---
```
#######################################
## 2.2. Host System Requirements
#######################################
start_timer "2.2. Host System Requirements"

pushd /bin
rm sh
ln -s bash sh
popd

apt-get update
apt-get updgrade

apt-get install -y \
  bash \
  binutils \
  bison \
  bzip2 \
  coreutils \
  gawk \
  gcc \
  g++ \
  libc6 \
  grep \
  gzip \
  m4 \
  make \
  patch \
  perl \
  sed \
  tar \
  texinfo \
  xz-utils

end_timer

```
---
```
#######################################
## 2.4. Creating a New Partition 
#######################################
start_timer "2.4. Creating a New Partition"

DEVICE=/dev/$DRIVE
PARTITION="$DEVICE$PARTITION_NUMBER"

fdisk $DEVICE << end
n
p
1


w
end


export LFS=/mnt/lfs
mkfs -v -t ext4 $PARTITION
mkdir -pv $LFShttp://www.linuxfromscratch.org/lfs/view/stable/index.html
echo -e "\n$PARTITION\t$LFS\text4\tdefaults\t0\t0\n" >> /etc/fstab
mount -a

end_timer

#######################################
## 2.6. Setting The $LFS Variable 
#######################################
echo -e "\nexport LFS=$LFS\n" >> .bashrc
source .bashrc

#######################################
## 3. All Packages
#######################################
start_timer "3. All Packages"

mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
wget http://www.linuxfromscratch.org/lfs/view/stable/wget-list
wget http://www.linuxfromscratch.org/lfs/view/stable/md5sums
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
pushd $LFS/sources
md5sum -c ~/md5sums
popd

end_timer

#######################################
## 4.2. Creating the $LFS/tools Directory
#######################################
mkdir -v $LFS/tools
ln -sv $LFS/tools /

#######################################
## 4.3. Adding the LFS User
#######################################
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
passwd lfs

```
---
```
chown -v lfs $LFS/tools
chown -v lfs $LFS/sources
su - lfs

```
---
```
#######################################
## 4.4. Setting Up the Environment
#######################################
start_timer "4.4. Setting Up the Environment"

cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF

source ~/.bash_profile

end_timer

#######################################
## 5.4. Binutils-2.31.1 - Pass 1 (1)
#######################################
start_package "5.4. Binutils-2.31.1 - Pass 1" binutils-2.31.1 tar.xz

mkdir -v build
cd       build

../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror

make

case $(uname -m) in
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac

make install

end_package

#######################################
## 5.5. GCC-8.2.0 - Pass 1 (14.3)
#######################################
start_package "5.5. GCC-8.2.0 - Pass 1" gcc-8.2.0 tar.xz

tar -xf ../mpfr-4.0.1.tar.xz
mv -v mpfr-4.0.1 mpfr
tar -xf ../gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac

mkdir -v build
cd       build

../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libmpx                               \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++
   
make
make install

end_package

#######################################
## 5.6. Linux-4.18.5 API Headers (0.1)
#######################################
start_package "5.6. Linux-4.18.5 API Headers" linux-4.18.5 tar.xz

make mrproper

make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include

end_package

#######################################
## 5.7. Glibc-2.28 (4.7)
#######################################
start_package "5.7. Glibc-2.28" glibc-2.28 tar.xz

mkdir -v build
cd       build

../configure                             \
      --prefix=/tools                    \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2             \
      --with-headers=/tools/include      \
      libc_cv_forced_unwind=yes          \
      libc_cv_c_cleanup=yes

make
make install 

end_package

#######################################
## Glibc-2.28 - Check
#######################################
echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'

# Expected 
#[Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2]
rm -v dummy.c a.out

```
---
```

#######################################
## 5.8. Libstdc++ from GCC-8.2.0 (0.5)
#######################################
start_package "5.8. Libstdc++ from GCC-8.2.0" gcc-8.2.0 tar.xz

mkdir -v build
cd       build

../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/8.2.0

make
make install

end_package

#######################################
## 5.9. Binutils-2.31.1 - Pass 2 (1.1)
#######################################
start_package "5.9. Binutils-2.31.1 - Pass 2" binutils-2.31.1 tar.xz

mkdir -v build
cd       build

CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                   \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot

make
make install

make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin

end_package

#######################################
## 5.10. GCC-8.2.0 - Pass 2 (11)
#######################################
start_package "5.10. GCC-8.2.0 - Pass 2" gcc-8.2.0 tar.xz

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

tar -xf ../mpfr-4.0.1.tar.xz
mv -v mpfr-4.0.1 mpfr
tar -xf ../gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

mkdir -v build
cd       build

CC=$LFS_TGT-gcc                                    \
CXX=$LFS_TGT-g++                                   \
AR=$LFS_TGT-ar                                     \
RANLIB=$LFS_TGT-ranlib                             \
../configure                                       \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp
    
make
make install

ln -sv gcc /tools/bin/cc

end_package

#######################################
## GCC-8.2.0 - Pass 2 - Check
#######################################
echo 'int main(){}' > dummy.c
cc dummy.c
readelf -l a.out | grep ': /tools'

# Expected
#[Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2]
rm -v dummy.c a.out

```
---
```
#######################################
## 5.11. Tcl-8.6.8 (0.9)
#######################################
start_package "5.11. Tcl-8.6.8" tcl8.6.8-src tar.gz tcl8.6.8

cd unix
./configure --prefix=/tools

make
make install

chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh

end_package

#######################################
## 5.12. Expect-5.45.4 
#######################################
start_package "5.12. Expect-5.45.4" expect5.45.4 tar.gz

cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure

./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include

make
make SCRIPTS="" install

end_package

#######################################
## 5.13. DejaGNU-1.6.1 
#######################################
start_package "5.13. DejaGNU-1.6.1" dejagnu-1.6.1 tar.gz

./configure --prefix=/tools
make install

end_package

#######################################
## 5.14. M4-1.4.18 
#######################################
start_package "5.14. M4-1.4.18" m4-1.4.18 tar.xz

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/tools

make
make install

end_package

#######################################
## 5.15. Ncurses-6.1 
#######################################
start_package "5.15. Ncurses-6.1" ncurses-6.1 tar.gz

sed -i s/mawk// configure

./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite

make
make install

end_package

#######################################
## 5.16. Bash-4.4.18 
#######################################
start_package "5.16. Bash-4.4.18" bash-4.4.18 tar.gz

./configure --prefix=/tools --without-bash-malloc
make
make install

ln -sv bash /tools/bin/sh

end_package

#######################################
## 5.17. Bison-3.0.5 
#######################################
start_package "5.17. Bison-3.0.5" bison-3.0.5 tar.xz

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.18. Bzip2-1.0.6 
#######################################
start_package "5.18. Bzip2-1.0.6" bzip2-1.0.6 tar.gz

make
make PREFIX=/tools install

end_package

#######################################
## 5.19. Coreutils-8.30 
#######################################
start_package "5.19. Coreutils-8.30" coreutils-8.30 tar.xz

./configure --prefix=/tools --enable-install-program=hostname
make
make install

end_package

#######################################
## 5.20. Diffutils-3.6 
#######################################
start_package "5.20. Diffutils-3.6" diffutils-3.6 tar.xz

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.21. File-5.34 
#######################################
start_package "5.21. File-5.34" file-5.34 tar.gz

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.22. Findutils-4.6.0 
#######################################
start_package "5.22. Findutils-4.6.0" findutils-4.6.0 tar.gz

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.23. Gawk-4.2.1 
#######################################
start_package "5.23. Gawk-4.2.1" gawk-4.2.1 tar.xz

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.24. Gettext-0.19.8.1 
#######################################
start_package "5.24. Gettext-0.19.8.1" gettext-0.19.8.1 tar.xz

cd gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared

make -C gnulib-lib
make -C intl pluralx.c
make -C src msgfmt
make -C src msgmerge
make -C src xgettext

cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin

end_package

#######################################
## 5.25. Grep-3.1 
#######################################
start_package "5.25. Grep-3.1" grep-3.1 tar.xz

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.26. Gzip-1.9 
#######################################
start_package "5.26. Gzip-1.9" gzip-1.9 tar.xz

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.27. Make-4.2.1 
#######################################
start_package "5.27. Make-4.2.1" make-4.2.1 tar.bz2

sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
./configure --prefix=/tools --without-guile
make
make install

end_package

#######################################
## 5.28. Patch-2.7.6 
#######################################
start_package "5.28. Patch-2.7.6" patch-2.7.6 tar.xz

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.29. Perl-5.28.0 
#######################################
start_package "5.29. Perl-5.28.0" perl-5.28.0 tar.xz

sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth
make
cp -v perl cpan/podlators/scripts/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.28.0
cp -Rv lib/* /tools/lib/perl5/5.28.0

end_package

#######################################
## 5.30. Sed-4.5 
#######################################
start_package "5.30. Sed-4.5" sed-4.5 tar.xz

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.31. Tar-1.30 
#######################################
start_package "5.31. Tar-1.30" tar-1.30 tar.xz

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.32. Texinfo-6.5 
#######################################
start_package "5.32. Texinfo-6.5" texinfo-6.5 tar.xz

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.33. Util-linux-2.32.1 
#######################################
start_package "5.33. Util-linux-2.32.1" util-linux-2.32.1 tar.xz

./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            --without-ncurses              \
            PKG_CONFIG=""

make
make install

end_package

#######################################
## 5.34. Xz-5.2.4 
#######################################
start_package "5.34. Xz-5.2.4" xz-5.2.4 tar.xz

./configure --prefix=/tools
make
make install

end_package

#######################################
## 5.35. Stripping 
#######################################
start_timer "5.35. Stripping"
strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*

rm -rf /tools/{,share}/{info,man,doc}

find /tools/{lib,libexec} -name \*.la -delete

end_timer
exit

```
---
```
#######################################
## 5.36. Changing Ownership 
#######################################
su -
```
---
```
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

end_timer

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
# Not Epected: I have not name! in prompt

```
---
check kernel
```
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

make check

end_timer

```
---
```
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

```
---
```
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
# Expected: [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
readelf -l a.out | grep ': /lib'

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
# Expected:
#/usr/lib/../lib/crt1.o succeeded
#/usr/lib/../lib/crti.o succeeded
#/usr/lib/../lib/crtn.o succeeded

grep -B1 '^ /usr/include' dummy.log
# Expected
##include <...> search starts here:
# /usr/include

grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
# Expected
#SEARCH_DIR("/usr/lib")
#SEARCH_DIR("/lib")

grep "/lib.*/libc.so.6 " dummy.log
# Expected: attempt to open /lib/libc.so.6 succeeded

grep found dummy.log
# Expected found ld-linux-x86-64.so.2 at /lib/ld-linux-x86-64.so.2

rm -v dummy.c a.out dummy.log

```
---
```
#######################################
## 6.11. Zlib-1.2.11 
#######################################
start_package "6.11. Zlib-1.2.11 make" zlib-1.2.11 tar.xz

./configure --prefix=/usr
make

make check

end_timer

```
---
```
start_timer "6.11. Zlib-1.2.11 make install"

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

make check

end_timer

```
---
```
start_timer "6.12. File-5.34 make install"

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

make check

end_timer

```
---
```
start_timer "6.14. M4-1.4.18 make install"

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

echo "quit" | ./bc/bc -l Test/checklib.b

end_timer

```
---
```
start_timer "6.15. Bc-1.07.1 make install"

make install

end_package

#######################################
## 6.16. Binutils-2.31.1 
#######################################
expect -c "spawn ls"
# Expected: 
#spawn ls

```
---
```
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

make -k check

end_timer

```
---
```
start_timer "6.16. Binutils-2.31.1 make install"

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

make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log

end_timer

```
#### Caution

The code in gmp is highly optimized for the processor where it is built. Occasionally, the code that detects the processor misidentifies the system capabilities and there will be errors in the tests or other applications using the gmp libraries with the message "Illegal instruction". In this case, gmp should be reconfigured with the option --build=x86_64-unknown-linux-gnu and rebuilt. 

## Continue
```
start_timer "6.17. GMP-6.1.2 install"

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

make check

end_timer

```
---
```
start_timer "6.18. MPFR-4.0.1 install"

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

make check

end_timer

```
---
```
start_timer "6.19. MPC-1.1.0 install"

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

end_timer

#######################################
## 6.20.2. Configuring Shadow 
#######################################
pwconv
grpconv
passwd root

```
---
```
end_package

#######################################
## 6.21. GCC-8.2.0 
#######################################
start_package "6.21. GCC-8.2.0 make" gcc-8.2.0 tar.xz

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

rm -f /usr/lib/gcc

mkdir -v build
cd       build

SED=sed                               \
../configure --prefix=/usr            \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-libmpx         \
             --with-system-zlib

make

ulimit -s 32768

rm ../gcc/testsuite/g++.dg/pr83239.C

chown -Rv nobody . 
su nobody -s /bin/bash -c "PATH=$PATH make -k check"

end_timer

```
---
```
../contrib/test_summary

```
---
```
start_timer "6.21. GCC-8.2.0 install"

make install

ln -sv ../usr/bin/cpp /lib

ln -sv gcc /usr/bin/cc

install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/8.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

end_timer

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
# Expected: [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
# Expected
#/usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/../../../../lib/crt1.o succeeded
#/usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/../../../../lib/crti.o succeeded
#/usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/../../../../lib/crtn.o succeeded

grep -B4 '^ /usr/include' dummy.log
# Expected
##include <...> search starts here:
# /usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/include
# /usr/local/include
# /usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/include-fixed
# /usr/include

grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
# Expected
#SEARCH_DIR("/usr/x86_64-pc-linux-gnu/lib64")
#SEARCH_DIR("/usr/local/lib64")
#SEARCH_DIR("/lib64")
#SEARCH_DIR("/usr/lib64")
#SEARCH_DIR("/usr/x86_64-pc-linux-gnu/lib")
#SEARCH_DIR("/usr/local/lib")
#SEARCH_DIR("/lib")
#SEARCH_DIR("/usr/lib");

grep "/lib.*/libc.so.6 " dummy.log
# Expected: attempt to open /lib/libc.so.6 succeeded

grep found dummy.log
# Expected: found ld-linux-x86-64.so.2 at /lib/ld-linux-x86-64.so.2

rm -v dummy.c a.out dummy.log

```
---
```
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

end_package

#######################################
## 6.22. Bzip2-1.0.6 
#######################################
start_package "6.22. Bzip2-1.0.6" bzip2-1.0.6 tar.gz

patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch

sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile

sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

make -f Makefile-libbz2_so
make clean

make

make PREFIX=/usr install

cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat

end_package

#######################################
## 6.23. Pkg-config-0.29.2
#######################################
start_package "6.23. Pkg-config-0.29.2 make" pkg-config-0.29.2 tar.gz


./configure --prefix=/usr              \
            --with-internal-glib       \
            --disable-host-tool        \
            --docdir=/usr/share/doc/pkg-config-0.29.2

make

make check

end_timer

```
---
```
start_timer "6.23. Pkg-config-0.29.2 install"

make install

end_package

#######################################
## 6.23. Pkg-config-0.29.2 
#######################################
start_package "6.23. Pkg-config-0.29.2" ncurses-6.1 tar.gz

sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in

./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --enable-widec

make

make install

mv -v /usr/lib/libncursesw.so.6* /lib

ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so

for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done

rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so

mkdir -v       /usr/share/doc/ncurses-6.1
cp -v -R doc/* /usr/share/doc/ncurses-6.1

end_package 

#######################################
## 6.25. Attr-2.4.48
#######################################
start_package "6.25. Attr-2.4.48 make" attr-2.4.48 tar.gz

./configure --prefix=/usr     \
            --bindir=/bin     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.4.48

make

make check

end_timer

```
---
```
start_timer "6.25. Attr-2.4.48 install"

make install

mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so

end_package

#######################################
## 6.26. Acl-2.2.53
#######################################
start_package "6.26. Acl-2.2.53" acl-2.2.53 tar.gz

./configure --prefix=/usr         \
            --bindir=/bin         \
            --disable-static      \
            --libexecdir=/usr/lib \
            --docdir=/usr/share/doc/acl-2.2.53

make

make install

mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so

end_package

#######################################
## 6.27. Libcap-2.25
#######################################
start_package "6.27. Libcap-2.25" libcap-2.25 tar.xz

sed -i '/install.*STALIBNAME/d' libcap/Makefile

make

make RAISE_SETFCAP=no lib=lib prefix=/usr install
chmod -v 755 /usr/lib/libcap.so

mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so

end_package

#######################################
## 6.28. Sed-4.5
#######################################
start_package "6.28. Sed-4.5 make" sed-4.5 tar.xz

sed -i 's/usr/tools/'                 build-aux/help2man
sed -i 's/testsuite.panic-tests.sh//' Makefile.in

./configure --prefix=/usr --bindir=/bin

make
make html

make check

end_timer

```
---
```
start_timer "6.28. Sed-4.5 install"

make install
install -d -m755           /usr/share/doc/sed-4.5
install -m644 doc/sed.html /usr/share/doc/sed-4.5

end_package

#######################################
## 6.29. Psmisc-23.1
#######################################
start_package "6.29. Psmisc-23.1" psmisc-23.1 tar.xz

./configure --prefix=/usr

make

make install

mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin

end_package

#######################################
## 6.30. Iana-Etc-2.30
#######################################
start_package "6.30. Iana-Etc-2.30" iana-etc-2.30 tar.bz2

make

make install

end_package

#######################################
## 6.31. Bison-3.0.5
#######################################
start_package "6.31. Bison-3.0.5" bison-3.0.5 tar.xz

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.0.5

make

make install

end_package

#######################################
## 6.32. Flex-2.6.4
#######################################
start_package "6.32. Flex-2.6.4 make" flex-2.6.4 tar.gz

sed -i "/math.h/a #include <malloc.h>" src/flexdef.h


HELP2MAN=/tools/bin/true \
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4

make

make check

end_timer

```
---
```
start_timer "6.32. Flex-2.6.4 install"

make install

ln -sv flex /usr/bin/lex

end_package

#######################################
## 6.33. Grep-3.1
#######################################
start_package "6.33. Grep-3.1 make" grep-3.1 tar.xz

./configure --prefix=/usr --bindir=/bin

make

make -k check

end_timer

```
---
```
start_timer "6.33. Grep-3.1 install"

make install

end_package

#######################################
## 6.34. Bash-4.4.18
#######################################
start_package "6.34. Bash-4.4.18 make" bash-4.4.18 tar.gz

./configure --prefix=/usr                       \
            --docdir=/usr/share/doc/bash-4.4.18 \
            --without-bash-malloc               \
            --with-installed-readline

make

chown -Rv nobody .
su nobody -s /bin/bash -c "PATH=$PATH make tests"

end_timer

```
---
```
start_timer "6.34. Bash-4.4.18 install"

make install
mv -vf /usr/bin/bash /bin

end_package

exec /bin/bash --login +h

```
---
check helper functions
```
#######################################
## 6.35. Libtool-2.4.6
#######################################
start_package "6.35. Libtool-2.4.6 make" libtool-2.4.6 tar.xz

./configure --prefix=/usr

make

make check

end_timer

```
---
```
start_timer "6.35. Libtool-2.4.6 install"

make install

end_package

#######################################
## 6.36. GDBM-1.17
#######################################
start_package "6.36. GDBM-1.17 make" gdbm-1.17 tar.gz

./configure --prefix=/usr \
            --disable-static \
            --enable-libgdbm-compat

make

make check

end_timer

```
---
```
start_timer "6.36. GDBM-1.17 install"

make install

end_package

#######################################
## 6.37. Gperf-3.1
#######################################
start_package "6.37. Gperf-3.1 make" gperf-3.1 tar.gz

./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1

make

make -j1 check

end_timer

```
---
```
start_timer "6.37. Gperf-3.1 install"

make install

end_package

#######################################
## 6.37. Gperf-3.1
#######################################
start_package "6.38. Expat-2.2.6 make" expat-2.2.6 tar.bz2

sed -i 's|usr/bin/env |bin/|' run.sh.in

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.2.6

make

make check

end_timer

```
---
```
start_timer "6.38. Expat-2.2.6 install"

make install

install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.6

end_package

#######################################
## 6.39. Inetutils-1.9.4
#######################################
start_package "6.39. Inetutils-1.9.4 make" inetutils-1.9.4 tar.xz

./configure --prefix=/usr        \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

make

make check

end_timer

```
---
```
start_timer "6.39. Inetutils-1.9.4 install"

make install

mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin


end_package

#######################################
## 6.40. Perl-5.28.0
#######################################
start_package "6.40. Perl-5.28.0 make" perl-5.28.0 tar.xz

echo "127.0.0.1 localhost $(hostname)" > /etc/hosts

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib                  \
                  -Dusethreads

make

make -k test

end_timer

```
---
```
start_timer "6.40. Perl-5.28.0 install"

make install
unset BUILD_ZLIB BUILD_BZIP2

end_package

#######################################
## 6.41. XML::Parser-2.44
#######################################
start_package "6.41. XML::Parser-2.44 make" XML-Parser-2.44 tar.gz

perl Makefile.PL

make

make test

end_timer

```
---
```
start_timer "6.41. XML::Parser-2.44 install"

make install

end_package

#######################################
## 6.42. Intltool-0.51.0
#######################################
start_package "6.42. Intltool-0.51.0 make" intltool-0.51.0 tar.gz

sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr

make

make check

end_timer

```
---
```
start_timer "6.42. Intltool-0.51.0 install"

make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

end_package

#######################################
## 6.43. Autoconf-2.69
#######################################
start_package "6.43. Autoconf-2.69 make" autoconf-2.69 tar.xz

./configure --prefix=/usr

make

make check

end_timer

```
---
```
start_timer "6.43. Autoconf-2.69 install"

make install

end_package

#######################################
## 6.44. Automake-1.16.1
#######################################
start_package "6.44. Automake-1.16.1 make" automake-1.16.1 tar.xz

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1

make

make -j4 check

end_timer

```
---
```
start_timer "6.44. Automake-1.16.1 install"

make install

end_package

#######################################
## 6.45. Xz-5.2.4
#######################################
start_package "6.45. Xz-5.2.4 make" xz-5.2.4 tar.xz

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.4

make

make check

end_timer

```
---
```
start_timer "6.45. Xz-5.2.4 install"

make install
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so

end_package

#######################################
## 6.46. Kmod-25
#######################################
start_package "6.46. Kmod-25 make" kmod-25 tar.xz

./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib

make

make install

for target in depmod insmod lsmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /sbin/$target
done

ln -sfv kmod /bin/lsmod

end_package

#######################################
## 6.47. Gettext-0.19.8.1
#######################################
start_package "6.47. Gettext-0.19.8.1 make" gettext-0.19.8.1 tar.xz

sed -i '/^TESTS =/d' gettext-runtime/tests/Makefile.in &&
sed -i 's/test-lock..EXEEXT.//' gettext-tools/gnulib-tests/Makefile.in

sed -e '/AppData/{N;N;p;s/\.appdata\./.metainfo./}' \
    -i gettext-tools/its/appdata.loc

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.19.8.1

make

make check

end_timer

```
---
```
start_timer "6.47. Gettext-0.19.8.1 install"

make install
chmod -v 0755 /usr/lib/preloadable_libintl.so

end_package

#######################################
## 6.48. Libelf 0.173
#######################################
start_package "6.48. Libelf 0.173 make" elfutils-0.173 tar.bz2

./configure --prefix=/usr

make

make check

end_timer

```
---
```
start_timer "6.48. Libelf 0.173 install"

make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig

end_package

#######################################
## 6.49. Libffi-3.2.1
#######################################
start_package "6.49. Libffi-3.2.1 make" libffi-3.2.1 tar.gz

sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
    -i include/Makefile.in

sed -e '/^includedir/ s/=.*$/=@includedir@/' \
    -e 's/^Cflags: -I${includedir}/Cflags:/' \
    -i libffi.pc.in

./configure --prefix=/usr --disable-static --with-gcc-arch=native

make

make check

end_timer

```
---
```
start_timer "6.49. Libffi-3.2.1 install"

make install

end_package

#######################################
## 6.50. OpenSSL-1.1.0i
#######################################
start_package "6.50. OpenSSL-1.1.0i make" openssl-1.1.0i tar.gz

./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic

make

make test

end_timer

```
---
```
start_timer "6.50. OpenSSL-1.1.0i install"

sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install

mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.0i
cp -vfr doc/* /usr/share/doc/openssl-1.1.0i

end_package

#######################################
## 6.51. Python-3.7.0
#######################################
start_package " make" Python-3.7.0 tar.xz

./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --with-ensurepip=yes

make

make install
chmod -v 755 /usr/lib/libpython3.7m.so
chmod -v 755 /usr/lib/libpython3.so

install -v -dm755 /usr/share/doc/python-3.7.0/html 

tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.7.0/html \
    -xvf ../python-3.7.0-docs-html.tar.bz2

end_package

#######################################
## 6.52. Ninja-1.8.2
#######################################
start_package "6.52. Ninja-1.8.2 make" ninja-1.8.2 tar.gz

export NINJAJOBS=4

patch -Np1 -i ../ninja-1.8.2-add_NINJAJOBS_var-1.patch

python3 configure.py
./ninja ninja_test
./ninja_test --gtest_filter=-SubprocessTest.SetWithLot

end_timer

```
---
```
start_timer " install"

install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja

end_package

#######################################
## 6.53. Meson-0.47.1
#######################################
start_package "6.53. Meson-0.47.1" meson-0.47.1 tar.gz

python3 setup.py build

python3 setup.py install --root=dest
cp -rv dest/* /

end_package

#######################################
## 6.54. Procps-ng-3.3.15
#######################################
start_package "6.54. Procps-ng-3.3.15 make" procps-ng-3.3.15 tar.xz

./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.15 \
            --disable-static                         \
            --disable-kill

make

sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
sed -i '/set tty/d' testsuite/pkill.test/pkill.exp
rm testsuite/pgrep.test/pgrep.exp
make check

end_timer

```
---
```
start_timer "6.54. Procps-ng-3.3.15 install"

make install

mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so

end_package

#######################################
## 6.55. E2fsprogs-1.44.3
#######################################
start_package "6.55. E2fsprogs-1.44.3 make" e2fsprogs-1.44.3 tar.gz

mkdir -v build
cd build

../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck

make

ln -sfv /tools/lib/lib{blk,uu}id.so.1 lib
make LD_LIBRARY_PATH=/tools/lib check

end_timer

```
---
```
start_timer "6.55. E2fsprogs-1.44.3 install"

make install

make install-libs

chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

end_package

#######################################
## 6.56. Coreutils-8.30
#######################################
start_package "6.56. Coreutils-8.30 make" coreutils-8.30 tar.xz

patch -Np1 -i ../coreutils-8.30-i18n-1.patch

sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk

autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime

FORCE_UNSAFE_CONFIGURE=1 make

### Test start here
make NON_ROOT_USERNAME=nobody check-root

echo "dummy:x:1000:nobody" >> /etc/group

chown -Rv nobody . 

su nobody -s /bin/bash \
          -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"

sed -i '/dummy/d' /etc/group

end_timer

```
---
```
start_timer "6.56. Coreutils-8.30 install"

make install

mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8

mv -v /usr/bin/{head,sleep,nice} /bin

end_package

#######################################
## 6.58. Diffutils-3.6
#######################################
start_package "6.58. Diffutils-3.6 make" diffutils-3.6 tar.xz

./configure --prefix=/usr

make

make check

end_timer

```
---
```
start_timer "6.58. Diffutils-3.6 install"

make install

end_package

#######################################
## 6.59. Gawk-4.2.1
#######################################
start_package "6.59. Gawk-4.2.1 make" gawk-4.2.1 tar.xz

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr

make

make check

end_timer

```
---
```
start_timer "6.59. Gawk-4.2.1 install"

make install

mkdir -v /usr/share/doc/gawk-4.2.1
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.2.1

end_package

#######################################
## 6.60. Findutils-4.6.0
#######################################
start_package "6.60. Findutils-4.6.0 make" findutils-4.6.0 tar.gz

sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

./configure --prefix=/usr --localstatedir=/var/lib/locate

make

make check

end_timer

```
---
```
start_timer "6.60. Findutils-4.6.0 install"

make install

mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb

end_package

#######################################
## 6.61. Groff-1.22.3
#######################################
start_package "6.61. Groff-1.22.3" groff-1.22.3 tar.gz 

PAGE=<paper_size> ./configure --prefix=/usr

make -j1

make install

end_package

#######################################
## 6.62. GRUB-2.02
#######################################
start_package "6.62. GRUB-2.02" grub-2.02 tar.xz

./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror

make

make install

end_package

#######################################
## 6.63. Less-530
#######################################
start_package "6.63. Less-530" less-530 tar.gz

./configure --prefix=/usr --sysconfdir=/etc

make

make install

end_package

#######################################
## 6.64. Gzip-1.9
#######################################
start_package "6.64. Gzip-1.9 make" gzip-1.9 tar.xz

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/usr

make

make check

end_timer

```
---
```
start_timer "6.64. Gzip-1.9 install"

make install

mv -v /usr/bin/gzip /bin

end_package

#######################################
## 6.65. IPRoute2-4.18.0
#######################################
start_package "6.65. IPRoute2-4.18.0" iproute2-4.18.0 tar.xz

sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

sed -i 's/.m_ipt.o//' tc/Makefile

make

make DOCDIR=/usr/share/doc/iproute2-4.18.0 install

end_package

#######################################
## 6.66. Kbd-2.0.4
#######################################
start_package "6.66. Kbd-2.0.4 make" kbd-2.0.4 tar.xz

patch -Np1 -i ../kbd-2.0.4-backspace-1.patch

sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock

make

make check

end_timer

```
---
```
start_timer "6.66. Kbd-2.0.4 install"

make install

mkdir -v       /usr/share/doc/kbd-2.0.4
cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.4

end_package

#######################################
## 6.67. Libpipeline-1.5.0
#######################################
start_package "6.67. Libpipeline-1.5.0 make" libpipeline-1.5.0 tar.gz

./configure --prefix=/usr

make

make check

end_timer

```
---
```
start_timer "6.67. Libpipeline-1.5.0 install"

make install

end_package

#######################################
## 6.68. Make-4.2.1
#######################################
start_package "6.68. Make-4.2.1 make" make-4.2.1 tar.bz2

sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c

./configure --prefix=/usr

make

make PERL5LIB=$PWD/tests/ check

end_timer

```
---
```
start_timer "6.68. Make-4.2.1 install"

make install

end_package

#######################################
## 6.69. Patch-2.7.6
#######################################
start_package "6.69. Patch-2.7.6 make" patch-2.7.6 tar.xz

./configure --prefix=/usr

make

make check

end_timer

```
---
```
start_timer "6.69. Patch-2.7.6 install"

make install

end_package

#######################################
## 6.70. Sysklogd-1.5.1
#######################################
start_package "6.70. Sysklogd-1.5.1" sysklogd-1.5.1 tar.gz

sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
sed -i 's/union wait/int/' syslogd.c

make

make BINDIR=/sbin install

cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF

end_package

#######################################
## 6.71. Sysvinit-2.90
#######################################
start_package "6.71. Sysvinit-2.90" sysvinit-2.90 tar.xz

patch -Np1 -i ../sysvinit-2.90-consolidated-1.patch

make -C src

make -C src install

end_package

#######################################
## 6.72. Eudev-3.2.5
#######################################
start_package "6.72. Eudev-3.2.5 make" eudev-3.2.5 tar.gz

cat > config.cache << "EOF"
HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I/tools/include"
EOF

./configure --prefix=/usr           \
            --bindir=/sbin          \
            --sbindir=/sbin         \
            --libdir=/usr/lib       \
            --sysconfdir=/etc       \
            --libexecdir=/lib       \
            --with-rootprefix=      \
            --with-rootlibdir=/lib  \
            --enable-manpages       \
            --disable-static        \
            --config-cache

LIBRARY_PATH=/tools/lib make

## Test start here
mkdir -pv /lib/udev/rules.d
mkdir -pv /etc/udev/rules.d

make LD_LIBRARY_PATH=/tools/lib check

end_timer

```
---
```
start_timer "6.72. Eudev-3.2.5 install"

make LD_LIBRARY_PATH=/tools/lib install

tar -xvf ../udev-lfs-20171102.tar.bz2
make -f udev-lfs-20171102/Makefile.lfs install

LD_LIBRARY_PATH=/tools/lib udevadm hwdb --update

end_package

#######################################
## 6.73. Util-linux-2.32.1
#######################################
start_package "6.73. Util-linux-2.32.1 make" util-linux-2.32.1 tar.xz

mkdir -pv /var/lib/hwclock

rm -vf /usr/include/{blkid,libmount,uuid}

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --docdir=/usr/share/doc/util-linux-2.32.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            --without-systemd    \
            --without-systemdsystemunitdir

make

## Test start here
#chown -Rv nobody .
#su nobody -s /bin/bash -c "PATH=$PATH make -k check"

end_timer

```
---
# Warning
Running the test suite as the root user can be harmful to your system. To run it, the CONFIG_SCSI_DEBUG option for the kernel must be available in the currently running system, and must be built as a module. Building it into the kernel will prevent booting. For complete coverage, other BLFS packages must be installed. If desired, this test can be run after rebooting into the completed LFS system and running:

bash tests/run.sh --srcdir=$PWD --builddir=$PWD
```
start_timer "6.73. Util-linux-2.32.1 install"

make install

end_package

#######################################
## 6.74. Man-DB-2.8.4
#######################################
start_package "6.74. Man-DB-2.8.4 make" man-db-2.8.4 tar.xz

./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.8.4 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --enable-cache-owner=bin             \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap            \
            --with-systemdtmpfilesdir=

make

make check

end_timer

```
---
```
start_timer "6.74. Man-DB-2.8.4 install"

make install

end_package

#######################################
## 6.75. Tar-1.30
#######################################
start_package "6.75. Tar-1.30 make" tar-1.30 tar.xz

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin

make

make check

end_timer

```
---
```
start_timer "6.75. Tar-1.30 install"

make install
make -C doc install-html docdir=/usr/share/doc/tar-1.30

end_package

#######################################
## 6.76. Texinfo-6.5
#######################################
start_package "6.76. Texinfo-6.5 make" texinfo-6.5 tar.xz

sed -i '5481,5485 s/({/(\\{/' tp/Texinfo/Parser.pm

./configure --prefix=/usr --disable-static

make

make check

end_timer

```
---
```
start_timer "6.76. Texinfo-6.5 install"

make install

make TEXMF=/usr/share/texmf install-tex

pushd /usr/share/info
rm -v dir
for f in *
  do install-info $f dir 2>/dev/null
done
popd

end_package

#######################################
## 6.77. Vim-8.1
#######################################
start_package "6.77. Vim-8.1 make" vim-8.1 tar.bz2

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

./configure --prefix=/usr

make

LANG=en_US.UTF-8 make -j1 test &> vim-test.log

end_timer

```
---
```
start_timer "6.77. Vim-8.1 install"

make install

ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done

ln -sv ../vim/vim81/doc /usr/share/doc/vim-8.1

cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1 

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF



end_package

```
---
```
#######################################
## 6.77. Nano-2.9.8
#######################################
start_package "6.77. Nano-2.9.8" nano-2.9.8 tar.xz

./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --enable-utf8     \
            --docdir=/usr/share/doc/nano-2.9.8 &&
make

make install &&
install -v -m644 doc/{nano.html,sample.nanorc} /usr/share/doc/nano-2.9.8

end_package

#######################################
## 6.79. Stripping Again
#######################################
start_timer "6.79. Stripping Again"

save_lib="ld-2.28.so libc-2.28.so libpthread-2.28.so libthread_db-1.0.so"

cd /lib

for LIB in $save_lib; do
    objcopy --only-keep-debug $LIB $LIB.dbg 
    strip --strip-unneeded $LIB
    objcopy --add-gnu-debuglink=$LIB.dbg $LIB 
done    

save_usrlib="libquadmath.so.0.0.0 libstdc++.so.6.0.25
             libitm.so.1.0.0 libatomic.so.1.2.0" 

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug $LIB $LIB.dbg
    strip --strip-unneeded $LIB
    objcopy --add-gnu-debuglink=$LIB.dbg $LIB
done

unset LIB save_lib save_usrlib

exec /tools/bin/bash

/tools/bin/find /usr/lib -type f -name \*.a \
   -exec /tools/bin/strip --strip-debug {} ';'

/tools/bin/find /lib /usr/lib -type f \( -name \*.so* -a ! -name \*dbg \) \
   -exec /tools/bin/strip --strip-unneeded {} ';'

/tools/bin/find /{bin,sbin} /usr/{bin,sbin,libexec} -type f \
    -exec /tools/bin/strip --strip-all {} ';'

end_timer

#######################################
## 6.80. Cleaning Up
#######################################

# rm -rf /tmp/*

logout

```
---
```

logout

chroot "$LFS" /usr/bin/env -i          \
    HOME=/root TERM="$TERM"            \
    PS1='(lfs chroot) \u:\w\$ '        \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login

end_timer

```
---
```
rm -f /usr/lib/lib{bfd,opcodes}.a
rm -f /usr/lib/libbz2.a
rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
rm -f /usr/lib/libltdl.a
rm -f /usr/lib/libfl.a
rm -f /usr/lib/libz.a

find /usr/lib /usr/libexec -name \*.la -delete

```
---
```
#######################################
## 7. System Configuration
#######################################

```