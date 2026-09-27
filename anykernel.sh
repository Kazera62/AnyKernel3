### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=Kazera M11/A11
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=1
device.name1=sdm450
device.name2=m11q
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

# boot shell variables
BLOCK=/dev/block/by-name/boot;
IS_SLOT_DEVICE=0;
RAMDISK_COMPRESSION=auto;
PATCH_VBMETA_FLAG=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# Patch only the active Qualcomm QCDT entry used by SDM450 + PMI632.
# The stock boot image's QCDT container is preserved; only DTB index 1 is replaced.
patch_qcdt_oc_dtb() {
	local magic version entries entry_base offset_field size_field offset size new_size padded
	local entry_dtb

	[ -f "$AKHOME/oc-dtb" ] || return 0
	[ -f "$SPLITIMG/dt" ] || abort "Qualcomm QCDT container not found in boot image."

	magic=$(od -An -tx1 -N4 "$SPLITIMG/dt" | tr -d ' \n')
	[ "$magic" = "51434454" ] || abort "Unsupported DT container: expected QCDT."

	version=$(od -An -tu4 -j4 -N4 "$SPLITIMG/dt" | tr -d ' \n')
	entries=$(od -An -tu4 -j8 -N4 "$SPLITIMG/dt" | tr -d ' \n')
	[ "$version" -ge 1 ] && [ "$version" -le 3 ] || abort "Unsupported QCDT version: $version."
	[ "$entries" -ge 2 ] || abort "QCDT does not contain DTB index 1."

	case "$version" in
		1)
			entry_base=32
			offset_field=44
			size_field=48
			;;
		2)
			entry_base=36
			offset_field=52
			size_field=56
			;;
		3)
			entry_base=52
			offset_field=84
			size_field=88
			;;
	esac

	offset=$(od -An -tu4 -j"$offset_field" -N4 "$SPLITIMG/dt" | tr -d ' \n')
	size=$(od -An -tu4 -j"$size_field" -N4 "$SPLITIMG/dt" | tr -d ' \n')
	[ "$offset" -gt 0 ] && [ "$size" -gt 0 ] || abort "Invalid QCDT index 1 offset/size."
	[ $((offset % 2048)) -eq 0 ] || abort "QCDT index 1 offset is not page aligned."
	[ $((size % 2048)) -eq 0 ] || abort "QCDT index 1 size is not page aligned."

	entry_dtb="$AKHOME/qcdt-entry-1.dtb"
	dd if="$SPLITIMG/dt" of="$entry_dtb" bs=2048 skip="$((offset / 2048))" count="$((size / 2048))" >/dev/null 2>&1 		|| abort "Unable to extract QCDT index 1."
	grep -a -q "SDM450 + PMI632 SOC" "$entry_dtb" || abort "QCDT index 1 is not SDM450 + PMI632."

	local oc_magic
	oc_magic=$(od -An -tx1 -N4 "$AKHOME/oc-dtb" | tr -d ' \\n')
	[ "$oc_magic" = "d00dfeed" ] || abort "OC DTB is not a valid flattened device tree."
	grep -a -q "SDM450 + PMI632 SOC" "$AKHOME/oc-dtb" || abort "OC DTB model mismatch."

	new_size=$(wc -c < "$AKHOME/oc-dtb")
	padded=$(( ((new_size + 2047) / 2048) * 2048 ))
	[ "$padded" -le "$size" ] || abort "OC DTB is larger than QCDT index 1 slot."

	cp -f "$SPLITIMG/dt" "$SPLITIMG/dt.oc"
	dd if=/dev/zero of="$SPLITIMG/dt.oc" bs=2048 seek="$((offset / 2048))" count="$((size / 2048))" conv=notrunc >/dev/null 2>&1 		|| abort "Unable to clear QCDT index 1."
	dd if="$AKHOME/oc-dtb" of="$SPLITIMG/dt.oc" bs=1 seek="$offset" conv=notrunc >/dev/null 2>&1 		|| abort "Unable to write OC DTB into QCDT."
	mv -f "$SPLITIMG/dt.oc" "$SPLITIMG/dt"
	rm -f "$entry_dtb"
}

# boot install
dump_boot; # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk
patch_qcdt_oc_dtb
write_boot; # use flash_boot to skip ramdisk repack, e.g. for devices with init_boot ramdisk
## end boot install


## init_boot files attributes
#init_boot_attributes() {
#set_perm_recursive 0 0 755 644 $RAMDISK/*;
#set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
#} # end attributes

# init_boot shell variables
#BLOCK=init_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;

# reset for init_boot patching
#reset_ak;

# init_boot install
#dump_boot; # unpack ramdisk since it is the new first stage init ramdisk where overlay.d must go

#write_boot;
## end init_boot install


## vendor_kernel_boot shell variables
#BLOCK=vendor_kernel_boot;
#IS_SLOT_DEVICE=1;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;

# reset for vendor_kernel_boot patching
#reset_ak;

# vendor_kernel_boot install
#split_boot; # skip unpack/repack ramdisk, e.g. for dtb on devices with hdr v4 and vendor_kernel_boot

#flash_boot;
## end vendor_kernel_boot install


## vendor_boot files attributes
#vendor_boot_attributes() {
#set_perm_recursive 0 0 755 644 $RAMDISK/*;
#set_perm_recursive 0 0 750 750 $RAMDISK/init* $RAMDISK/sbin;
#} # end attributes

# vendor_boot shell variables
#BLOCK=vendor_boot;
#IS_SLOT_DEVICE=0;
#RAMDISK_COMPRESSION=auto;
#PATCH_VBMETA_FLAG=auto;

# reset for vendor_boot patching
#reset_ak;

# vendor_boot install
#dump_boot; # use split_boot to skip ramdisk unpack, e.g. for dtb on devices with hdr v4 but no vendor_kernel_boot

#write_boot; # use flash_boot to skip ramdisk unpack, e.g. for dtb on devices with hdr v4 but no vendor_boot
## end vendor_boot install
