#!/bin/bash
# Mainline U-Boot for Hugsun X88PRO (RK3518).

set -e
[ -d rkbin ]  || git clone --depth 1 https://github.com/rockchip-linux/rkbin
[ -d u-boot ] || git clone --depth 1 -b v2026.07 https://github.com/u-boot/u-boot
cd u-boot
export BL31=../rkbin/bin/rk35/rk3528_bl31_v1.21.elf
export ROCKCHIP_TPL=../rkbin/bin/rk35/rk3528_ddr_1056MHz_4BIT_PCB_D4_eyescan_v1.14.bin  # needed by the build, not used on the board
make generic-rk3528_defconfig
./scripts/config --set-val SYS_MMC_MAX_BLK_COUNT 2048   # large single SD reads fail on this board
make olddefconfig
make -j"$(nproc)"
ls -l u-boot.itb
