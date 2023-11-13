#
# SPDX-FileCopyrightText: 2023-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Enable updating of APEXes
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

# Inherit generic_ramdisk product configuration
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# Installs gsi keys into ramdisk, to boot a developer GSI with verified boot.
$(call inherit-product, $(SRC_TARGET_DIR)/product/developer_gsi_keys.mk)

DEVICE_PATH := device/xiaomi/emerald
KERNEL_PATH := $(DEVICE_PATH)-kernel

# Shipping API level
PRODUCT_SHIPPING_API_LEVEL := 33

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Inherit the proprietary files
$(call inherit-product, vendor/xiaomi/emerald/emerald-vendor.mk)
