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
  xz-utils \
  && end_timer

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
