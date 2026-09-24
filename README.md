# Armbian on Hugsun X88PRO RK3518 box ("TV98")

**Current state:**
- **Working:** Ethernet, HDMI console, SD, eMMC, USB (using armbian vendor 6.1 kernel)
- **Not working:** Wi-Fi/BT, probably fixable, but I am too lazy. See `wifi/README.md`.

## eMMC content

| Sector | Content |
|---|---|
| 64 | Factory idbloader: DDR v1.13 (`3d08567393 huan.he 26/04/02`, DDR4) + Rockchip SPL v1.06 |
| 16384 | Mainline U-Boot 2026.07 `u-boot.itb` (`generic-rk3528_defconfig`, BL31 v1.21, `SYS_MMC_MAX_BLK_COUNT=2048`) |
| 32768+ | ext4 rootfs, DTB `rockchip/rk3518-hugsun-x88pro.dtb` |

Public rkbin DDR blobs and Armbian's own rk3528 loader (BL31 v1.17) are **not** used. 

**Do NOT use `armbian-install`**: use `x88pro-install-emmc`, which is included in the image. You will brick your box if you don't since it will load a significantly older loader.

## lLayout

| Path | What |
|---|---|
| `armbian/userpatches/` | Armbian build config: board `.csc`, DTS, loader files, eMMC installer, DTB guard. Copy into `armbian-build/userpatches/`. |
| `armbian/run-build.sh` | The exact `compile.sh` invocation |
| `u-boot/` | `build.sh`, the full `.config`, the built `u-boot.itb` |
| `images/` | Local build output |
| `.github/workflows/` | CI image build |
| `recovery/` | Maskrom loader, restore-SD image, stock U-Boot (see Recovery) |
| `wifi/` | SeekWave SWT6621S notes |

## CI build (GitHub Actions)

`.github/workflows/build-image.yml` builds the SD card image on GitHub's runners, from `armbian/userpatches` and a pinned `armbian/build` commit. Make `linux/` the repository root.
- Run it from the Actions tab (**Build SD card image → Run workflow**). You can override the Armbian ref and the release.
- Or push a `v*` tag, which also attaches the image to a GitHub Release.
- The job checks that the factory idbloader (sector 64) and `u-boot.itb` (sector 16384) are in the image, then uploads the image as an artifact.
- A full build takes roughly 1 to 1.5 h on a 4-core runner, since the vendor kernel is compiled from scratch.

## Brick prevention

Since we needed a custom dtb to fix hardware diff between this and RK ref boards, `rk3518-hugsun-x88pro.dtb` is used, if an official Armbian `linux-dtb-vendor-rk35xx` upgrade repoints `/boot/dtb` to a directory without that file, the box would stop booting. `x88pro-dtb-guard` prevents this in a non-intrusive (we hope) manner, which copies `/usr/lib/x88pro/rk3518-hugsun-x88pro.dtb` periodically to /boot/dtb

It's included in the image. Our kernel adds only the DTB, so official `linux-image/dtb-vendor-rk35xx` and `armbian-firmware` are a drop-in replacement.