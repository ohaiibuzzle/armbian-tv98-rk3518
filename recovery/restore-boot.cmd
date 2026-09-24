# X88PRO restore: put the stock Android U-Boot back into the eMMC "uboot" partition.
echo "=== X88PRO restore: writing stock U-Boot to eMMC ==="
setenv emmc
for n in 0 1 2; do
	if test -z "${emmc}" && part start mmc ${n} uboot ustart && part size mmc ${n} uboot usize; then
		if test "${usize}" = "2000"; then setenv emmc ${n}; fi
	fi
done
if test -z "${emmc}"; then echo "No eMMC with a 4 MiB uboot partition found; not writing anything."; exit; fi
echo "eMMC is mmc ${emmc}, uboot partition at sector 0x${ustart}"
load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} stock_uboot.img
if test "${filesize}" != "400000"; then echo "stock_uboot.img has wrong size ${filesize}; not writing."; exit; fi
mmc dev ${emmc}
mmc write ${kernel_addr_r} ${ustart} 2000
mmc read ${ramdisk_addr_r} ${ustart} 2000
if cmp.b ${kernel_addr_r} ${ramdisk_addr_r} 400000; then
	echo "Stock U-Boot restored and verified. Remove the SD card; resetting."
	sleep 3
	reset
else
	echo "VERIFY FAILED"
fi
