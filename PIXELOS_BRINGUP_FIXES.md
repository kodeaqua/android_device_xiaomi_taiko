# taiko — PixelOS (sixteen-qpr2) bring-up fixes

Device tree + blobs were dumped from CrDroid 16 / adapted from a LineageOS 23 tree.
PixelOS builds far more of AOSP from source, so a number of proprietary blobs now
collide with source-built modules. Fixes below make `breakfast taiko && m pixelos`
reach the compile stage.

Repos touched: `vendor/xiaomi/taiko`, `device/xiaomi/taiko`
Branches renamed to `sixteen-qpr2`: `device/xiaomi/taiko`, `device/xiaomi/taiko-kernel`,
`vendor/xiaomi/taiko`, `hardware/xiaomi` (local branch name only; upstream tracking
refs unchanged — `repo sync` is driven by the manifest, not these names).

---

## 1. Soong packaging conflict — vendor/bin utilities (7)

`soong_filesystem_creator` (A16 generated vendor image) hard-errors when two modules
install the same `vendor/bin/*` path. Proprietary prebuilts collided with AOSP's
`toybox_vendor` / `dumpsys_vendor` / `boringssl_self_test_vendor`.

Removed `cc_prebuilt_binary` blocks from `Android.bp` + entries from
`taiko-vendor.mk` PRODUCT_PACKAGES:

- `blkdiscard`, `getfattr`, `getopt`, `setfattr`  (→ `toybox_vendor`)
- `dumpsys`                                        (→ `dumpsys_vendor`)
- `boringssl_self_test32`, `boringssl_self_test64` (→ `boringssl_self_test_vendor`)

## 2. Make module name collision — "already defined by vendor/xiaomi/taiko" (4)

Prebuilt binaries whose module name matches an AOSP source module (both soong).
`prefer: true` does not dedup across partition variants → duplicate
`MODULE.TARGET.EXECUTABLES.*`.

Removed from `Android.bp` + `taiko-vendor.mk`:

| module            | AOSP source                                      |
|-------------------|--------------------------------------------------|
| `test-nusensors`  | `hardware/libhardware/tests/nusensors`           |
| `hs20-osu-client` | `external/wpa_supplicant_8/hs20/client`          |
| `trusty-ut-ctrl`  | `system/core/trusty/utils/trusty-ut-ctrl`        |
| `wpa_cli`         | `external/wpa_supplicant_8/wpa_supplicant`       |

(`test-nusensor`, singular, has no AOSP collision — kept.)

## 3. VINTF manifest overriding-commands (1)

`prebuilt_etc` `bluetooth_audio.xml` (MediaTek BT-audio VINTF fragment) installs the
same path as AOSP `hardware/interfaces/bluetooth/audio/aidl/default/bluetooth_audio.xml`.
Both declare `android.hardware.bluetooth.audio` v5 `IBluetoothAudioProviderFactory/default`
— functionally identical.

Removed `prebuilt_etc_xml` block from `Android.bp` + entry from `taiko-vendor.mk`.

## 4. PRODUCT_COPY_FILES vs soong-built files — overriding commands (17)

Blob copies of files PixelOS now builds from source. Removed from `taiko-vendor.mk`
PRODUCT_COPY_FILES (device-specific `*_mtk` variants of hfp/le_audio configs kept):

```
vendor/etc/aidl/hfp/hfp_codec_capabilities.xml
vendor/etc/aidl/le_audio/aidl_audio_set_configurations.bfbs
vendor/etc/aidl/le_audio/aidl_audio_set_scenarios.bfbs
vendor/etc/aidl/le_audio/aidl_default_audio_set_configurations.json
vendor/etc/aidl/le_audio/aidl_default_audio_set_scenarios.json
vendor/etc/boringssl_self_test.no_zygote.rc
vendor/etc/boringssl_self_test.zygote32.rc
vendor/etc/boringssl_self_test.zygote64.rc
vendor/etc/boringssl_self_test.zygote64_32.rc
vendor/etc/build_flags.json
vendor/etc/fstab.enableswap
vendor/etc/init/android.hardware.health-service.example.rc
vendor/etc/init/android.hardware.sensors-service-multihal.rc
vendor/etc/init/android.hardware.wifi.supplicant-service.rc
vendor/etc/init/boringssl_self_test.rc
vendor/etc/init/vndservicemanager.rc
vendor/etc/mkshrc
```

## 5. proprietary-files.txt sync

Removed the 29 corresponding entries (11 `vendor/bin/*` + 18 `vendor/etc/*`, incl.
`vendor/etc/vintf/manifest/bluetooth_audio.xml`) from
`device/xiaomi/taiko/proprietary-files.txt` so re-running extract-utils does not
re-add them. Blob files under `proprietary/` left in place (untracked, harmless).

---

## Deferred (needs a booted ROM to confirm what's actually used)

- `lineage_taiko.mk` — dead product file (not in `AndroidProducts.mk`), safe to delete.
- `overlay-lineage/` (`LineageSDKOverlayMT6789` → `lineageos.platform`,
  `LineageApertureOverlayMT6789` → `org.lineageos.aperture`) — only if PixelOS does
  not ship LineageSDK / Aperture (`vendor/lineage` and `packages/apps/Aperture` are
  currently synced).
- `*.lineage` HALs (`android.hardware.light-service.lineage`,
  `android.hardware.power-service.lineage-libperfmgr`,
  `hardware/lineage/interfaces/power-libperfmgr`) — these are common custom-ROM HALs,
  currently load-bearing; leave unless replaced.
