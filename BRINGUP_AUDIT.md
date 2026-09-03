# taiko — PixelOS bring-up audit (sixteen-qpr2)

Audit of `device/xiaomi/taiko`, `device/xiaomi/taiko-kernel`, `vendor/xiaomi/taiko`
against **`xiaomi-mt6789-devs/android_device_xiaomi_yunluo`** (`lineage-23.0`, a
working MT6789 / Android-16 tree — taiko was converted from it) and the **stock
fastboot ROM `OS3.0.304.0.WOVMIXM`** (`/mnt/d/taiko_global_images_...`).

Tree compiled but had **never booted**. Symptom: bootlogo → reboot loop (2–5 s),
recovery also loops.

---

## FIXED — boot-blocking

### F1. Vendor ramdisk shipped only the modules listed in `modules.load` (195), not all 210

```
- BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(addprefix $(KERNEL_PATH)/ramdisk/, \
-     $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD))
+ BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/ramdisk/*.ko)
```

`modules.load` names 195 modules; the kernel's `ramdisk/` and the **stock**
vendor_boot ramdisk both carry **210**. The extra 15 are dependency-/softdep-only
targets: `arm_dsu_pmu kshrink_slabd metis mi_schedule mi_thermal_notify
mi_unfairmem mtk-mbox mtk_rpmsg_mbox mtk_tinysys_ipi perf_helper reboot-mode
scene_swappiness sec syscon-reboot-mode xiaomi_usb_touch_notifier`.
`mtk-mbox` / `mtk_tinysys_ipi` (SCP/MCUPM/SSPM mailbox) are pulled in by listed
modules (`mtk-scpsys*`, clk, etc.); with them absent, first-stage `modprobe`
fails on a hard dependency → reboot loop (recovery loads the same set → also
loops). `modules.load` / `modules.load.recovery` still drive load *order*; this
just makes the *set* complete. This tree already does exactly this for
`vendor_dlkm` (`$(wildcard .../vendor_dlkm/*.ko)`), and so does yunluo.

**Verified:** rebuilt `vendor_boot.img` went from 195 → 210 `.ko`.

### F2. First-stage `fstab.mt6789` was never staged into the vendor ramdisk

`BoardConfig.mk` sets `TARGET_RECOVERY_FSTAB` (recovery only). The blob
`taiko-vendor.mk` copies `fstab.mt6789` to `/vendor/etc/` (second stage only).
Nothing put it in the vendor ramdisk's `first_stage_ramdisk/`, where GKI
first-stage init reads it. **Verified:** our `vendor_boot.img` had no
`first_stage_ramdisk/fstab.mt6789`; **stock has it.** No fstab in first stage →
`init` cannot mount system/vendor → abort → reboot loop (recovery too).

**Fix** (`device.mk`) — mirror the pre-existing `fstab.enableswap` line:
```
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init/fstab.mt6789:$(TARGET_VENDOR_RAMDISK_OUT)/first_stage_ramdisk/fstab.mt6789
```
(`/vendor/etc/fstab.mt6789` is left to the blob copy to avoid a duplicate rule.)

---

## Checked and CLEARED (not bugs)

| Suspected | Reality |
|---|---|
| Kernel `Image.gz` vs `.ko` vermagic mismatch (`g6e872b4863d6` vs `g457c92b54ba8`) | **Stock is identical** — Xiaomi ships certified GKI + own vendor modules; `modversions` tolerates it |
| `dtb` / `dtbo` wrong | `dtb/taiko.dtb` md5 == stock; `dtbo` inner FDT == stock (whole-file md5 differs only by AVB footer) |
| `init.insmod.mt6789.cfg` missing → `wait_for_prop vendor.all.modules.ready` hang | **The blob provides it** at `vendor/xiaomi/taiko/proprietary/vendor/etc/init.insmod.mt6789.cfg` (copied by `taiko-vendor.mk`); content is the standard `modprobe|*` + `setprop|vendor.all.modules.ready`. Not a bug — my earlier `find` was mis-scoped to `device/` only. |
| Connectivity (wmt/wlan/bt) not loaded | Blob `/vendor/etc/init/init.{wmt,wlan,bt}_drv.rc` handle it |
| `boot.img` carries a 2.9 MB generic ramdisk (stock's is kernel-only) | Both valid for `launch_with_vendor_ramdisk`; taiko has no `init_boot` partition so the generic ramdisk lives in `boot.img` |
| `ueventd.rc`, wifi/BT firmware (86), Mali libs (17), KeyMint/Gatekeeper MiTEE HALs + `.rc` | all present and installed |

---

## Deferred — degraded, not boot-blocking (address from logcat once booting)

* **SELinux** — no `device/xiaomi/taiko/sepolicy/`, does not include
  `device/mediatek/sepolicy_vndr/SEPolicy.mk` (yunluo does). Worked around with
  `androidboot.selinux=permissive` on the kernel cmdline. Proper fix: sync
  `device/mediatek/sepolicy_vndr`, `BOARD_VENDOR_SEPOLICY_DIRS +=
  $(DEVICE_PATH)/sepolicy/vendor`, port yunluo's `sepolicy/vendor/` (16 files),
  drop the `permissive` cmdline.
* **Cellular** — `init.mt6789.rc` imports `init.modem.rc`, `init.volte.rc`,
  `init.mal.rc`, `init.hq.ext.rc`, `init.mt6789.power.rc`; the CrDroid blob dump
  omitted `/vendor/etc/init/hw/`, so these are absent. `import` of a missing file
  is logged, not fatal (`vold.post_fs_data_done` is set by core `init.rc`, not
  `init.modem.rc` — stale comment). Extract from the stock `vendor` partition
  into `vendor/xiaomi/taiko/proprietary/vendor/etc/init/hw/` + `taiko-vendor.mk`.
* **VINTF** — hand-rolled `framework_compatibility_matrix.xml`; earlier added the
  missing `vendor.mediatek.hardware.mtkpower` AIDL v3. yunluo instead reuses
  `hardware/mediatek/vintf/…` + `hardware/xiaomi/vintf/…` +
  `vendor/lineage/config/device_framework_matrix.xml`.
* `PRODUCT_SHIPPING_API_LEVEL := 35` (taiko launched on API 33 — cosmetic/CTS);
  `BOARD_HAS_MTK_HARDWARE`/`BOARD_VENDOR` present in yunluo, dropped here.

---

## Flash (recovery-sideload)

```
fastboot flash boot        boot.img
fastboot flash dtbo        dtbo.img
fastboot flash vendor_boot vendor_boot.img
fastboot reboot recovery
adb sideload PixelOS_taiko-16.2-*.zip     # writes all logical + boot partitions
```
`vbmeta` built with `--flags 3` (verity + verification disabled) — no vbmeta
flash needed on an unlocked bootloader.

Still looping? `adb shell dmesg`, `adb logcat -b all -d`,
`adb shell cat /sys/fs/pstore/console-ramoops*` (from recovery).
