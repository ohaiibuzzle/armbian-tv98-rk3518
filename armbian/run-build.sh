#!/bin/bash
# ~/armbian-build is armbian/build checked out at v26.5.1 (REVISION below names the image after it).
# ~/swt6621s (or SWT6621S_SRC) is https://github.com/ohaiibuzzle/swt6621s; needs debhelper and build-essential.
set -e
SWT6621S_SRC="${SWT6621S_SRC:-$HOME/swt6621s}"
(cd "$SWT6621S_SRC" && dpkg-buildpackage -us -uc -b)
rm -f ~/armbian-build/userpatches/x88pro/swt6621s-dkms_*.deb
cp -v "$SWT6621S_SRC"/../swt6621s-dkms_*.deb ~/armbian-build/userpatches/x88pro/
set +e

cd ~/armbian-build
./compile.sh build BOARD=hugsun-x88pro BRANCH=vendor RELEASE=trixie BUILD_MINIMAL=yes BUILD_DESKTOP=no \
  KERNEL_CONFIGURE=no KERNEL_GIT=shallow DEBIAN_MIRROR=cdn-aws.deb.debian.org/debian \
  DEBIAN_SECURITY=cdn-aws.deb.debian.org/debian-security COMPRESS_OUTPUTIMAGE=sha,xz SHARE_LOG=no \
  REVISION=26.5.1
echo $? > ~/build.exit
