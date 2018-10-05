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
