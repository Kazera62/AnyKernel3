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

# Patch only the appended DTB entry used by SDM450 + PMI632.
# Samsung's stock boot image for this device uses a legacy Android boot
# header with three raw FDT blobs appended to the kernel payload. It does not
# use a QCDT container. Preserve DTB 0 and DTB 2 byte-for-byte and replace
# only DTB 1 with the OC build.
patch_kernel_dtb_oc() {
	local source total offset dtb_size magic idx next expected_end tmp

	[ -f "$AKHOME/oc-dtb" ] || return 0
	[ -f "$SPLITIMG/kernel_dtb" ] || abort "Appended kernel DTB payload not found in boot image."

	magic=$(od -An -tx1 -N4 "$AKHOME/oc-dtb" | tr -d ' \
')
	[ "$magic" = "d00dfeed" ] || abort "OC DTB is not a valid flattened device tree."

grep -q "SDM450 + PMI632 SOC" "$AKHOME/oc-dtb" || abort "OC DTB model mismatch."

	source="$SPLITIMG/kernel_dtb"
	total=$(wc -c < "$source")
	offset=0
	idx=0
	tmp="$SPLITIMG/kernel_dtb.oc"

	: > "$tmp" || abort "Unable to create kernel DTB work file."

	while [ "$offset" -lt "$total" ]; do
		[ $((total - offset)) -ge 8 ] || abort "Truncated kernel DTB payload."

		magic=$(dd if="$source" bs=1 skip="$offset" count=4 2>/dev/null | od -An -tx1 | tr -d ' \
')
		[ "$magic" = "d00dfeed" ] || abort "Invalid FDT magic at kernel DTB index $idx."

		set -- $(dd if="$source" bs=1 skip=$((offset + 4)) count=4 2>/dev/null | od -An -tx1)
		[ "$#" -eq 4 ] || abort "Unable to read FDT size at kernel DTB index $idx."
		dtb_size=$((0x$1 << 24 | 0x$2 << 16 | 0x$3 << 8 | 0x$4))
		[ "$dtb_size" -ge 40 ] || abort "Invalid FDT size at kernel DTB index $idx."
		expected_end=$((offset + dtb_size))
		[ "$expected_end" -le "$total" ] || abort "Kernel DTB index $idx exceeds payload bounds."

		case "$idx" in
			1)
				if ! dd if="$source" bs=1 skip="$offset" count="$dtb_size" 2>/dev/null | grep -q "SDM450 + PMI632 SOC"; then
					abort "Stock kernel DTB index 1 is not SDM450 + PMI632."
				fi
				cat "$AKHOME/oc-dtb" >> "$tmp" || abort "Unable to append OC DTB."
				;;
			*)
				dd if="$source" bs=1 skip="$offset" count="$dtb_size" 2>/dev/null >> "$tmp" || abort "Unable to preserve kernel DTB index $idx."
				;;
		esac

		idx=$((idx + 1))
		offset="$expected_end"
	done

	[ "$idx" -ge 2 ] || abort "Kernel DTB payload does not contain DTB index 1."
	mv -f "$tmp" "$source" || abort "Unable to install patched kernel DTB payload."
}

# boot install
dump_boot; # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk
patch_kernel_dtb_oc
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
