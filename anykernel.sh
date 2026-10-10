### AnyKernel3 Ramdisk Mod Script
## Based on AnyKernel3 by osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=NOCTURNE // SDM450
do.devicecheck=1
do.modules=1
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=m11q
device.name2=m11
device.name3=a11q
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot files attributes
boot_attributes() {
set_perm_recursive 0 0 755 644 $RAMDISK/*;
set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
} # end attributes

# Samsung Galaxy M11 / A11 use a non-A/B boot partition.
BLOCK=boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# Boot image install.
# No device-specific ramdisk edits are applied.
dump_boot;
write_boot;
## end boot install
