#
# SPDX-FileCopyrightText: 2023-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/emerald
KERNEL_PATH := $(DEVICE_PATH)-kernel

# Enable updating of APEXes
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

# Inherit generic_ramdisk product configuration
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# Installs gsi keys into ramdisk, to boot a developer GSI with verified boot.
$(call inherit-product, $(SRC_TARGET_DIR)/product/developer_gsi_keys.mk)

# A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

# Boot Control
PRODUCT_PACKAGES += \
    android.hardware.boot-service.default \
    android.hardware.boot-service.default_recovery

# Dynamic Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_SUPER_PARTITION := false

# Shipping API level
PRODUCT_SHIPPING_API_LEVEL := 33

# Rootdir
PRODUCT_PACKAGES += \
    fstab.mt6789 \
    fstab.mt6789.vendor_ramdisk

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/init/init.recovery.mt6789.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6789.rc

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Inherit the proprietary files
$(call inherit-product, vendor/xiaomi/emerald/emerald-vendor.mk)
