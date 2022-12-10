#
# SPDX-FileCopyrightText: 2023-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from device makefile.
$(call inherit-product, device/xiaomi/emerald/device.mk)

# Inherit some common LineageOS stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_emerald
PRODUCT_DEVICE := emerald
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := emerald

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="emerald-user 14 UP1A.231005.007 V816.0.5.0.UFOMIXM release-keys" \
    BuildFingerprint=Redmi/emerald_global/emerald:14/UP1A.231005.007/V816.0.5.0.UFOMIXM:user/release-keys \
    SystemName=emerald_global \
    SystemDevice=emerald
