# Rockchip RK3518 quad core 1.5GB DDR4 8GB eMMC TV box (Hugsun X88PRO DDR4 V10, "TV98")
BOARD_NAME="Hugsun X88PRO RK3518"
BOARD_VENDOR="hugsun"
BOARDFAMILY="rk35xx"
BOARD_MAINTAINER=""
KERNEL_TARGET="vendor"
BOOT_SOC="rk3528"
BOOT_FDT_FILE="rockchip/rk3518-hugsun-x88pro.dtb"
IMAGE_PARTITION_TABLE="gpt"
SERIALCON="ttyFIQ0:1500000"
PACKAGE_LIST_BOARD="gdisk rsync"

# Armbian's rk3528 loader (public DDR blob + BL31 v1.17) does not boot this board.
# The loader is built outside Armbian instead: the board's own factory idbloader
# (DDR v1.13 DDR4 + Rockchip SPL v1.06) at sector 64 and a mainline U-Boot
# 2026.07 u-boot.itb (BL31 v1.21) at sector 16384. Both live in userpatches/x88pro.
BOOTCONFIG="none"

X88PRO_LOADER_DIR="${SRC}/userpatches/x88pro"

function post_family_tweaks__x88pro_install_loader_files() {
	display_alert "$BOARD" "Installing loader files and eMMC installer" "info"
	mkdir -p "${SDCARD}/usr/lib/x88pro-loader"
	cp -v "${X88PRO_LOADER_DIR}/factory_idbloader_x88pro.bin" "${X88PRO_LOADER_DIR}/u-boot.itb" "${SDCARD}/usr/lib/x88pro-loader/"
	install -m 0755 "${X88PRO_LOADER_DIR}/x88pro-install-emmc" "${SDCARD}/usr/local/sbin/x88pro-install-emmc"

	# DTB guard: puts rk3518-hugsun-x88pro.dtb back into /boot/dtb/rockchip after every
	# dpkg run and hourly, so an official kernel upgrade cannot leave the box without it.
	install -m 0755 "${X88PRO_LOADER_DIR}/x88pro-dtb-guard" "${SDCARD}/usr/local/sbin/x88pro-dtb-guard"
	install -m 0644 "${X88PRO_LOADER_DIR}/99x88pro-dtb-guard" "${SDCARD}/etc/apt/apt.conf.d/99x88pro-dtb-guard"
	install -m 0644 "${X88PRO_LOADER_DIR}/x88pro-dtb-guard.service" "${X88PRO_LOADER_DIR}/x88pro-dtb-guard.timer" "${SDCARD}/etc/systemd/system/"
	install -m 0644 "${X88PRO_LOADER_DIR}/99x88pro-official-kernel.pref" "${SDCARD}/etc/apt/preferences.d/99x88pro-official-kernel"
	mkdir -p "${SDCARD}/etc/systemd/system/timers.target.wants"
	ln -sf ../x88pro-dtb-guard.timer "${SDCARD}/etc/systemd/system/timers.target.wants/x88pro-dtb-guard.timer"
}

function pre_umount_final_image__x88pro_write_loader() {
	display_alert "$BOARD" "Writing factory idbloader @64 and mainline u-boot.itb @16384 to ${LOOP}" "info"
	dd if="${X88PRO_LOADER_DIR}/factory_idbloader_x88pro.bin" of="${LOOP}" bs=512 seek=64 conv=notrunc,fsync status=none
	dd if="${X88PRO_LOADER_DIR}/u-boot.itb" of="${LOOP}" bs=512 seek=16384 conv=notrunc,fsync status=none

	# uart2 is the Bluetooth UART on this board, so keep the kernel console off ttyS2
	# (boot-rk35xx.cmd adds console=ttyS2 for console=serial/both). The last console=
	# becomes /dev/console, so list tty1 last: HDMI is the only console most boxes have.
	sed -i 's/^console=.*/console=display/' "${MOUNT}/boot/armbianEnv.txt"
	echo "extraargs=earlycon=uart8250,mmio32,0xff9f0000 console=ttyFIQ0,1500000 console=tty1" >> "${MOUNT}/boot/armbianEnv.txt"

	# Seed the DTB guard's master copy from this build's kernel package.
	mkdir -p "${MOUNT}/usr/lib/x88pro"
	cp "${MOUNT}/boot/dtb/rockchip/rk3518-hugsun-x88pro.dtb" "${MOUNT}/usr/lib/x88pro/"
	chroot "${MOUNT}" dpkg-query -W -f='${Version}\n' linux-dtb-vendor-rk35xx > "${MOUNT}/usr/lib/x88pro/rk3518-hugsun-x88pro.dtb.pkgver"
}
