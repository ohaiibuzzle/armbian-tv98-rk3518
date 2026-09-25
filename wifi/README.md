# Wi-Fi / BT: SeekWave SWT6621S (SV6160LITE)

**Status: Wi-Fi works.** Firmware downloads, the CP boots, `wlan0` comes up and
scans (142 BSSes on a 39-channel pass). **Bluetooth works:** `hci0` comes up
unblocked and powered, and LE scans find nearby devices. Packaged as DKMS so it
rebuilds on every kernel upgrade.

## What the hardware is

- The module sits on `sdio1` and enumerates as SDIO `1ffe:6621` (`mmc2: new ultra high speed SDR104 SDIO card`).
- No in-tree driver claims it.
- Stock Android loaded `skw_sdio_lite.ko` + `swt6621s_wifi.ko`.

## Driver (DKMS)

The driver lives in https://github.com/ohaiibuzzle/swt6621s (fork of
https://github.com/WLTB-Gino/swt6621s with the 6.1 fixes and Debian packaging).
Its `swt6621s-dkms` package ships the source to `/usr/src/swt6621s-25.34.7.1`,
the upstream-drop SDIO/USB firmware to `/lib/firmware` (NV `SHARE` installed as
`SWT6621S_NV_SDIO.bin`) and the Bluetooth NV files (`sv6160lite.nvbin`, identical
to the stock Android one).

**In the image:** the Armbian build compiles the .deb from the fork (CI input
`swt6621s_ref`), installs it with `linux-headers-vendor-rk35xx`, builds the modules
for the image kernel, and writes `/etc/modules-load.d/swt6621s.conf`. None of the
modules has a device table, so that file is what loads them at boot. `bluez` is
included for `bluetoothctl`. DKMS rebuilds the modules on every kernel upgrade.

**On an existing box:**

```
sudo apt install linux-headers-vendor-rk35xx ./swt6621s-dkms_25.34.7.1-2_all.deb
sudo dkms install -m swt6621s -v 25.34.7.1 -k "$(uname -r)"
printf '%s\n' swt6621s_wifi skw_sdio_lite skwbt | sudo tee /etc/modules-load.d/swt6621s.conf
```

Boxes flashed before the `wireless-bluetooth` DT change (see Bluetooth below) also need
the node disabled, or BT stays rfkill-blocked. The DTB guard installs whatever is in
its master copy:

```
sudo fdtput -t s /usr/lib/x88pro/rk3518-hugsun-x88pro.dtb /wireless-bluetooth status disabled
sudo x88pro-dtb-guard && sudo reboot
```

Fixes vs. the vendor drop (kernel `6.1.115-vendor-rk35xx`):

- `skw_compat.h`: `cfg80211_ch_switch_{started_,}notify()` gained `link_id` in 6.1 (the drop passed one extra argument).
- `Makefile`: add `-I$(src)/include` (some files use the `linux/platform_data/...` form) and `-DCONFIG_SKW_HOST_PLATFORM_ROCKCHIP`.
- `seekwaveplatform_lite/Makefile`: define `CONFIG_BT_SEEKWAVE` when `skwbt` is built. The drop only
  defines it on non-binder kernels, and the Rockchip vendor kernel has `CONFIG_ANDROID_BINDER_IPC=y`.

## Bluetooth

As on Android, BT runs over SDIO, not uart2 (stock `skwbt.conf` uses `/dev/BTCMD`,
`/dev/BTDATA`, ...). On Linux, the BSP registers a `btseekwave` platform device and
`skwbt` (`drivers/swtbt4l`) binds it as `hci0`, loading `sv6160lite.nvbin`.

The DT's `wireless-bluetooth` node (Rockchip `rfkill_bt`, meant for UART BT) is
**disabled**. That driver registers a persistent `bt_default` rfkill switch that
starts blocked, and the rfkill core copies that state to every bluetooth switch, so
`hci0` came up soft-blocked (`PowerState: off-blocked`). The chip does not need that
driver's reset GPIO: firmware download and `hci0` setup happen without it.

## Notes / remaining

- The DT still has `sdio-pwrseq` owning gpio3 PB2 and no `WIFI,poweren_gpio`.
  Boot logs warn `chip_en:-1 Invalid Pls check HW` and `no support gpio irq`, but
  Wi-Fi works anyway. The README recipe below is still the right fix if cold-boot
  or recovery turns out flaky.
- EFUSE MAC is invalid, so a random locally-administered MAC is generated each boot.
  Set one via the `wireless-wlan` DT node or a udev rule if it matters.
- Reloading `skw_sdio_lite` without a reboot fails (`probe ... failed with error -110`,
  `wait scan card time out`): the chip needs a real power cycle. Reboot instead.

## Background recipe (historical)

1. **Driver source:** the GitHub drop; its `drivers/seekwaveplatform_lite/sdio` lists `SDIO_DEVICE(0x1FFE, 0x6621)`.
2. **Firmware** in `/lib/firmware`:
   - `SWT6621S_IRAM_SDIO.bin`, `SWT6621S_DRAM_SDIO.bin`, `SWT6621S_NV_SDIO.bin`
     (the board's NV is byte-identical to the drop's `SWT6621S_NV_SDIO_SHARE.bin`,
     so the package installs SHARE as `SWT6621S_NV_SDIO.bin`).
   - `SWT6621S_SEEKWAVE_R00001.bin` (RF calibration, downloaded at probe).
   - The stock Android set is in `android-vendor-firmware/` as a fallback (not used by the package).
3. **DT power model** (only if needed):
   - In `wireless-wlan`, add `WIFI,poweren_gpio = <&gpio3 RK_PB2 GPIO_ACTIVE_HIGH>;`.
   - Make `sdio_pwrseq` pinctrl-only (drop `reset-gpios`).
4. **Load order:** core first is fine; the BSP registers `sv6621s_wireless1` and the
   core's `sv6621s_wireless1` platform driver binds to it.
5. **Bluetooth:** `swtbt4l` in the same repo (see above).
