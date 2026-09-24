# Wi-Fi / BT: SeekWave SWT6621S (SV6160LITE)

**Status: idk it probably will work but i don't care™**

## What the hardware is

- The module sits on `sdio1` and enumerates as SDIO `1ffe:6621` (`mmc2: new ultra high speed SDR104 SDIO card`).
- No driver in the Armbian vendor 6.1 kernel claims it.
- Stock Android loaded `skw_sdio_lite.ko` + `swt6621s_wifi.ko`.

## Likely recipe

1. **Driver source:** https://github.com/WLTB-Gino/swt6621s (GPL vendor drop `SWT6621S_H25.34.7.1`). Its `drivers/seekwaveplatform_lite/sdio` lists `SDIO_DEVICE(0x1FFE, 0x6621)`. The README only covers USB, so build the SDIO backend with something like:
   ```
   make -C /lib/modules/$(uname -r)/build M=$PWD \
     CONFIG_SEEKWAVE_BSP_DRIVERS=m CONFIG_SKW_SDIOHAL=m CONFIG_WLAN_VENDOR_SWT6621S=m \
     skw_extra_flags+=-DCONFIG_SKW_HOST_PLATFORM_ROCKCHIP modules
   ```
   This needs `linux-headers-vendor-rk35xx`.

2. **Firmware** goes in `/lib/firmware`:
   - `SWT6621S_IRAM_SDIO.bin` and `SWT6621S_DRAM_SDIO.bin`. 
   - `SWT6621S_NV_SDIO.bin`. The board's NV is byte-identical to the drop's `SWT6621S_NV_SDIO_SHARE.bin` (shared Wi-Fi/BT antenna).
   - The set Android shipped is in `android-vendor-firmware/` as a fallback. Its IRAM, DRAM and RF calibration files differ from the GitHub drop's.
3. **DT: probably has to follow Android's power model** so the driver can power-cycle the chip:
   - In `wireless-wlan`, add `WIFI,poweren_gpio = <&gpio3 RK_PB2 GPIO_ACTIVE_HIGH>;`.
   - Make `sdio_pwrseq` pinctrl-only (drop `reset-gpios`).
   - The current DTS gives gpio3 PB2 to `mmc-pwrseq`, which works for enumeration but not for the driver's `rockchip_wifi_power()` resets.
4. **Load order:** `modprobe skw_sdio_lite` first; the Wi-Fi core is loaded on demand.
5. **Bluetooth:** later, via `swtbt4l` in the same repo, with `sv6160lite.nvbin` and `skwbt.conf` from `android-vendor-firmware/`.
