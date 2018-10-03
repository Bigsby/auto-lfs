## 2.2. Host System Requirements
```
pushd /bin
sudo rm sh
sudo ln -s bash sh
popd
sudo apt-get install -y \
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

```

## 2.4. Creating a New Partition 
```
sudo fdisk /dev/sdb << end
n
p
1


w
end

sudo mkfs -v -t ext4 /dev/sdb1
sudo mkdir -pv /mnt/lfs
sudo echo -e "\n/dev/sdb1\t/mnt/lfs\text4\tdefaults\t0\t0\n" >> /etc/fstab
sudo mount -a

```
## 2.6. Setting The $LFS Variable 
```
echo -e "\nexport LFS=/mnt/lfs\n" >> .bashrc
source .bashrc

```
## 3. All Packages
```
sudo mkdir -v $LFS/sources
sudo chmod -v a+wt $LFS/sources
wget http://www.linuxfromscratch.org/lfs/view/stable/wget-list
http://www.linuxfromscratch.org/lfs/view/stable/md5sums
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
pushd $LFS/sources
md5sum -c ~/md5sums
popd

```
## 4.2. Creating the $LFS/tools Directory
```
sudo mkdir -v $LFS/tools
sudo ln -sv $LFS/tools /

```
## 4.3. Adding the LFS User
```
sudo groupadd lfs
sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
sudo passwd lfs

```
```
sudo chown -v lfs $LFS/tools
sudo chown -v lfs $LFS/sources
su - lfs

```
## 4.4. Setting Up the Environment
```
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

```
## 5.4. Binutils-2.31.1 - Pass 1
```
cd $LFS/sources
tar xfv binutils-2.31.1.tar.xz
cd binutils-2.31.1

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

cd $LFS/sources
rm -rf binutils-2.31.1

```
## 5.5. GCC-8.2.0 - Pass 1
```
cd $LFS/sources
tar xfv gcc-8.2.0.tar.xz
cd gcc-8.2.0

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

cd $LFS/sources
rm -rf gcc-8.2.0

```
## 5.6. Linux-4.18.5 API Headers
```
cd $LFS/sources
tar xfv linux-4.18.5.tar.xz
cd linux-4.18.5

make mrproper
make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include

cd $LFS/sources
rm -rf linux-4.18.5

```
## 5.7. Glibc-2.28
```
cd $LFS/sources
tar xfv glibc-2.28.tar.xz
cd glibc-2.28

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

cd $LFS/sources
rm -rf glibc-2.28

```
## Glibc-2.28 - Check
```
echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'
# Expected [Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2]
rm -v dummy.c a.out
```
## 5.8. Libstdc++ from GCC-8.2.0
```
cd $LFS/sources
tar xfv gcc-8.2.0.tar.xz
cd gcc-8.2.0

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

cd $LFS/sources
rm -rf gcc-8.2.0

```
## 5.9. Binutils-2.31.1 - Pass 2
```
cd $LFS/sources
tar xfv binutils-2.31.1.tar.xz
cd binutils-2.31.1

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

cd $LFS/sources
rm -rf binutils-2.31.1

```
## 5.10. GCC-8.2.0 - Pass 2 
```
cd $LFS/sources
tar xfv gcc-8.2.0.tar.xz
cd gcc-8.2.0

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

cd $LFS/sources
rm -rf gcc-8.2.0

```
## GCC-8.2.0 - Pass 2 - Check
```
echo 'int main(){}' > dummy.c
cc dummy.c
readelf -l a.out | grep ': /tools'
# Expected [Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2]
rm -v dummy.c a.out

```
## 5.11. Tcl-8.6.8 
```
cd $LFS/sources
tar xfv tcl8.6.8-src.tar.gz
cd tcl8.6.8-src

cd unix
./configure --prefix=/tools

make
make install

chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh

cd $LFS/sources
rm -rf tcl8.6.8-src

```
## 5.12. Expect-5.45.4 
```
cd $LFS/sources
tar xfv expect5.45.4.tar.gz
cd expect5.45.4



cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure

./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include

make
make SCRIPTS="" install

cd $LFS/sources
rm -rf expect5.45.4

```
## 5.13. DejaGNU-1.6.1 
```
cd $LFS/sources
tar xfv dejagnu-1.6.1.tar.gz
cd dejagnu-1.6.1

./configure --prefix=/tools
make install

cd $LFS/sources
rm -rf dejagnu-1.6.1

```
## 5.14. M4-1.4.18 
```
cd $LFS/sources
tar xfv m4-1.4.18.tar.xz
cd m4-1.4.18

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

make
make install

cd $LFS/sources
rm -rf m4-1.4.18

```
## 5.15. Ncurses-6.1 
```
cd $LFS/sources
tar xfv ncurses-6.1.tar.gz
cd ncurses-6.1

sed -i s/mawk// configure

./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite

make
make install

cd $LFS/sources
rm -rf ncurses-6.1

```
## 5.16. Bash-4.4.18 
```
cd $LFS/sources
tar xfv bash-4.4.18.tar.gz
cd bash-4.4.18

./configure --prefix=/tools --without-bash-malloc
make
make install

ln -sv bash /tools/bin/sh

cd $LFS/sources
rm -rf bash-4.4.18

```
## 5.17. Bison-3.0.5 
```
cd $LFS/sources
tar xfv bison-3.0.5.tar.xz
cd bison-3.0.5

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf bison-3.0.5

```
## 5.18. Bzip2-1.0.6 
```
cd $LFS/sources
tar xfv bzip2-1.0.6.tar.gz
cd bzip2-1.0.6

make
make PREFIX=/tools instal

cd $LFS/sources
rm -rf bzip2-1.0.6

```
## 5.19. Coreutils-8.30 
```
cd $LFS/sources
tar xfv coreutils-8.30.tar.xz
cd coreutils-8.30

./configure --prefix=/tools --enable-install-program=hostname
make
make install

cd $LFS/sources
rm -rf coreutils-8.30

```
## 5.20. Diffutils-3.6 
```
cd $LFS/sources
tar xfv diffutils-3.6.tar.xz
cd diffutils-3.6

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf diffutils-3.6

```
## 5.21. File-5.34 
```
cd $LFS/sources
tar xfv file-5.34.tar.gz
cd file-5.34

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf file-5.34

```
## 5.22. Findutils-4.6.0 
```
cd $LFS/sources
tar xfv findutils-4.6.0.tar.gz
cd findutils-4.6.0

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf findutils-4.6.0

```
## 5.23. Gawk-4.2.1 
```
cd $LFS/sources
tar xfv gawk-4.2.1.tar.xz
cd gawk-4.2.1

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf gawk-4.2.1

```
## 5.24. Gettext-0.19.8.1 
```
cd $LFS/sources
tar xfv gettext-0.19.8.1.tar.xz
cd gettext-0.19.8.1

cd gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared

make -C gnulib-lib
make -C intl pluralx.c
make -C src msgfmt
make -C src msgmerge
make -C src xgettext

cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin

cd $LFS/sources
rm -rf gettext-0.19.8.1

```
## 5.25. Grep-3.1 
```
cd $LFS/sources
tar xfv grep-3.1.tar.xz
cd grep-3.1

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf grep-3.1

```
## 5.26. Gzip-1.9 
```
cd $LFS/sources
tar xfv gzip-1.9.tar.xz
cd gzip-1.9

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf gzip-1.9

```
## 5.27. Make-4.2.1 
```
cd $LFS/sources
tar xfv make-4.2.1.tar.bz2
cd make-4.2.1

sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
./configure --prefix=/tools --without-guile
make
make install

cd $LFS/sources
rm -rf make-4.2.1

```
## 5.28. Patch-2.7.6 
```
cd $LFS/sources
tar xfv patch-2.7.6.tar.xz
cd patch-2.7.6

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf patch-2.7.6

```
## 5.29. Perl-5.28.0 
```
cd $LFS/sources
tar xfv perl-5.28.0.tar.xz
cd perl-5.28.0

sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth
make
cp -v perl cpan/podlators/scripts/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.28.0
cp -Rv lib/* /tools/lib/perl5/5.28.0

cd $LFS/sources
rm -rf perl-5.28.0

```
## 5.30. Sed-4.5 
```
cd $LFS/sources
tar xfv sed-4.5.tar.xz
cd sed-4.5

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf sed-4.5

```
## 5.31. Tar-1.30 
```
cd $LFS/sources
tar xfv tar-1.30.tar.xz
cd tar-1.30

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf tar-1.30

```
## 5.32. Texinfo-6.5 
```
cd $LFS/sources
tar xfv texinfo-6.5.tar.xz
cd texinfo-6.5

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf texinfo-6.5

```
## 5.33. Util-linux-2.32.1 
```
cd $LFS/sources
tar xfv util-linux-2.32.1.tar.xz
cd util-linux-2.32.1

./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            --without-ncurses              \
            PKG_CONFIG=""

make
make install

cd $LFS/sources
rm -rf util-linux-2.32.1

```
## 5.34. Xz-5.2.4 
```
cd $LFS/sources
tar xfv xz-5.2.4.tar.xz
cd xz-5.2.4

./configure --prefix=/tools
make
make install

cd $LFS/sources
rm -rf xz-5.2.4

```
## 5.35. Stripping 
```
strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*

rm -rf /tools/{,share}/{info,man,doc}

find /tools/{lib,libexec} -name \*.la -delete

```
## 5.36. Changing Ownership 
```
chown -R root:root $LFS/tools

```
## 6.2. Preparing Virtual Kernel File Systems 
```
su -

```
```
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

```
## 6.4. Entering the Chroot Environment 
```
su -

```
```
chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h
    
```
## 6.5. Creating Directories 
```
su -

```
```
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

```
## 6.6. Creating Essential Files and Symlinks 
```
su -
```
```
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

```
## Check
```
exec /tools/bin/bash --login +h

```
## 6.7. Linux-4.18.5 API Headers 
```
cd /sources
tar xfv linux-4.18.5.tar.xz
cd linux-4.18.5

make mrproper

make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include

cd /sources
rm -rf linux-4.18.5

```
## 6.8. Man-pages-4.16 
```
cd /sources
tar xfv man-pages-4.16.tar.xz
cd man-pages-4.16

make install

cd $LFS/sources
rm -rf man-pages-4.16

```
## 6.9. Glibc-2.28 
```
cd /sources
tar xfv glibc-2.28.tar.xz
cd glibc-2.28

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
             --enable-kernel=3.2                    \
             --enable-stack-protector=strong        \
             libc_cv_slibdir=/lib
unset GCC_INCDIR

make

```
## CHECK
```
make check

```
## Continue
```
touch /etc/ld.so.conf

sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

make install

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

```
## 6.9.2. Configuring Glibc 
```
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

```
## 6.9.2.3. Configuring the Dynamic Loader 
```
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

```
## Finish 6.9. Glibc-2.28 
```
cd /sources
rm -rf glibc-2.28

```
## 6.10. Adjusting the Toolchain 
```
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld

gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs

```
## Check
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
## 6.11. Zlib-1.2.11 
```
cd /sources
tar xfv zlib-1.2.11.tar.xz
cd zlib-1.2.11

./configure --prefix=/usr
make

```
## Test
```
make check

```
```
make install

mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so

cd /sources
rm -rf zlib-1.2.11

```
## 6.12. File-5.34 
```
cd /sources
tar xfv file-5.34.tar.gz
cd file-5.34

./configure --prefix=/usr
make

```
## Test
```
make check

```
```
make install

cd /sources
rm -rf file-5.34

```
## 6.13. Readline-7.0 
```
cd /sources
tar xfv readline-7.0.tar.gz
cd readline-7.0

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

cd /sources
rm -rf readline-7.0.tar.gz

```
## 6.14. M4-1.4.18 
```
cd /sources
tar xfv m4-1.4.18.tar.xz
cd m4-1.4.18

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/usr

make

```
## Test
```
make check

```
## Continue
```
make install

cd /sources
rm -rf m4-1.4.18

```
## 6.15. Bc-1.07.1 
```
cd /sources
tar xfv bc-1.07.1.tar.gz
cd bc-1.07.1

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

```
## Test
```


echo "quit" | ./bc/bc -l Test/checklib.b

```
## Continue
```
make install

cd /sources
rm -rf bc-1.07.1

```
## 6.16. Binutils-2.31.1 
```
expect -c "spawn ls"
# Expected: spawn ls

```
## Go
```
cd /sources
tar xfv binutils-2.31.1.tar.xz
cd binutils-2.31.1

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

```
## Test
```
make -k check

```
## Continue
```
make tooldir=/usr install

cd /sources
rm -rf binutils-2.31.1

```
## 6.17. GMP-6.1.2 
```
cd /sources
tar xfv gmp-6.1.2.tar.xz
cd gmp-6.1.2
```
Optional for cross
```
cp -v configfsf.guess config.guess
cp -v configfsf.sub   config.sub
```
Continue
```
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.1.2

make
make html

```
## Test
```
make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log

```
#### Caution

The code in gmp is highly optimized for the processor where it is built. Occasionally, the code that detects the processor misidentifies the system capabilities and there will be errors in the tests or other applications using the gmp libraries with the message "Illegal instruction". In this case, gmp should be reconfigured with the option --build=x86_64-unknown-linux-gnu and rebuilt. 

## Continue
```
make install
make install-html

cd /sources
rm -rf gmp-6.1.2

```
## 6.18. MPFR-4.0.1 
```
cd /sources
tar xfv mpfr-4.0.1.tar.xz
cd mpfr-4.0.1

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.0.1

make
make html

```
## Test
```
make check

```
## Continue
```
make install
make install-html

cd /sources
rm -rf mpfr-4.0.1

```
## 6.19. MPC-1.1.0 
```
cd /sources
tar xfv mpc-1.1.0.tar.gz
cd mpc-1.1.0

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.1.0

make
make html

```
## Test
```
make check

```
## Continue
```
make install
make install-html

cd /sources
rm -rf mpc-1.1.0

```
## 6.20. Shadow-4.6 
```
cd /sources
tar xfv shadow-4.6.tar.xz
cd shadow-4.6

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
```
## 6.20.2. Configuring Shadow 
```
pwconv
grpconv
passwd root

```

```
cd /sources
rm -rf shadow-4.6

```
## 6.21. GCC-8.2.0 
```
cd /sources
tar xfv gcc-8.2.0.tar.xz
cd gcc-8.2.0

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

```
## Test
```
ulimit -s 32768

rm ../gcc/testsuite/g++.dg/pr83239.C

chown -Rv nobody . 
su nobody -s /bin/bash -c "PATH=$PATH make -k check"

```
finally...
```
../contrib/test_summary

```
## Continue
```
make install

ln -sv ../usr/bin/cpp /lib

ln -sv gcc /usr/bin/cc

install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/8.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

```
## Check
```
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
## Continue
```
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

cd /sources
rm -rf gcc-8.2.0

```
## 6.22. Bzip2-1.0.6 
```
cd /sources
tar xfv bzip2-1.0.6.tar.gz
cd bzip2-1.0.6



cd /sources
rm -rf bzip2-1.0.6

```
