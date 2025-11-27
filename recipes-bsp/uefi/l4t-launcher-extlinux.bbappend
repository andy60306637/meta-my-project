# Fix do_install to handle devicetree/ subdirectory paths in FDT/FDTOVERLAYS
# This overrides the original do_install to properly handle paths with devicetree/ prefix

do_install() {
    install -d ${D}${L4T_EXTLINUX_BASEDIR}/extlinux
    install -m 0644 ${B}/${KERNEL_IMAGETYPE} ${D}${L4T_EXTLINUX_BASEDIR}/
    
    # Handle FDT installation with devicetree/ subdirectory support
    if [ -n "${L4T_UBOOT_EXTLINUX_FDT}" ]; then
        case "${L4T_UBOOT_EXTLINUX_FDT}" in
            devicetree/*)
                # Create devicetree subdirectory
                install -d ${D}${L4T_EXTLINUX_BASEDIR}/devicetree
                # Get basename without devicetree/ prefix
                dtb_basename=$(basename ${L4T_UBOOT_EXTLINUX_FDT})
                # Install from ${B}/ to ${D}/boot/devicetree/
                install -m 0644 ${B}/${dtb_basename}* ${D}${L4T_EXTLINUX_BASEDIR}/devicetree/
                ;;
            *)
                # No devicetree/ prefix, install directly to /boot/
                install -m 0644 ${B}/${L4T_UBOOT_EXTLINUX_FDT}* ${D}${L4T_EXTLINUX_BASEDIR}/
                ;;
        esac
    fi
    
    # Handle DTBO overlays installation with devicetree/ subdirectory support
    if [ -n "${UBOOT_EXTLINUX_FDTOVERLAYS}" ]; then
        for overlay in ${UBOOT_EXTLINUX_FDTOVERLAYS}; do
            case "${overlay}" in
                devicetree/*)
                    # Create devicetree subdirectory if not already created
                    install -d ${D}${L4T_EXTLINUX_BASEDIR}/devicetree
                    # Get basename without devicetree/ prefix
                    dtbo_basename=$(basename ${overlay})
                    # Install from ${B}/ to ${D}/boot/devicetree/
                    install -m 0644 ${B}/${dtbo_basename}* ${D}${L4T_EXTLINUX_BASEDIR}/devicetree/
                    ;;
                *)
                    # No devicetree/ prefix, install directly to /boot/
                    install -m 0644 ${B}/${overlay}* ${D}${L4T_EXTLINUX_BASEDIR}/
                    ;;
            esac
        done
    fi
    
    # Handle initrd installation
    if [ -n "${INITRAMFS_IMAGE}" -a "${INITRAMFS_IMAGE_BUNDLE}" != "1" ]; then
        install -m 0644 ${B}/initrd* ${D}${L4T_EXTLINUX_BASEDIR}/
    fi
    
    # Install extlinux.conf
    install -m 0644 ${B}/extlinux.conf* ${D}${L4T_EXTLINUX_BASEDIR}/extlinux/
}

