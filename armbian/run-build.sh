#!/bin/bash
cd ~/armbian-build
./compile.sh build BOARD=hugsun-x88pro BRANCH=vendor RELEASE=trixie BUILD_MINIMAL=yes BUILD_DESKTOP=no \
  KERNEL_CONFIGURE=no KERNEL_GIT=shallow DEBIAN_MIRROR=cdn-aws.deb.debian.org/debian \
  DEBIAN_SECURITY=cdn-aws.deb.debian.org/debian-security COMPRESS_OUTPUTIMAGE=sha,xz SHARE_LOG=no
echo $? > ~/build.exit
