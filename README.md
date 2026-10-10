# NOCTURNE AnyKernel3 — SDM450

Device-specific AnyKernel3 installer for the NOCTURNE kernel targeting Samsung Galaxy M11 and Galaxy A11 variants based on Snapdragon 450.

## Target device identifiers

The installer checks these product identifiers:

- `m11q`
- `m11`
- `a11q`

Compatibility still depends on the exact phone variant, firmware, boot image format, and testing on the target device.

## Installer configuration

The tracked `anykernel.sh` is configured directly for this device family:

- Uses `BLOCK=boot;` for the boot partition.
- Uses `IS_SLOT_DEVICE=0` for the non-A/B partition layout.
- Keeps device verification enabled.
- Supports optional kernel-module installation when modules are included in the ZIP.
- Does not apply device-specific ramdisk modifications.

The upstream build workflow clones this repository at build time and packages the installer as-is. Device-specific installer configuration is maintained here, not patched by the kernel build workflow.

## Packaging

Place the compiled kernel image (and any required DTB/DTBO or modules) in the AnyKernel3 staging directory and package it with the standard AnyKernel3 tools. The NOCTURNE GitHub Actions workflow uses the `AnyKernel3` packing method and leaves module packaging disabled by default.

Do not flash an untested build without a known-good boot image and a recovery method available. A successful build does not guarantee that every M11/A11 variant will boot.

## Credits and license

This repository is based on **AnyKernel3 by osm0sis**. The upstream license and required framework files are retained in this repository; see `LICENSE`.
