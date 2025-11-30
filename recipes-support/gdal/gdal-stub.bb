SUMMARY = "GDAL stub library for VisionRT"
DESCRIPTION = "Provides a stub libgdal.so to satisfy linking requirements"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PROVIDES = "gdal"
RPROVIDES:${PN} = "gdal"

do_compile() {
    # Create an empty stub library
    ${CC} ${CFLAGS} ${LDFLAGS} -shared -o libgdal.so.33 -Wl,-soname,libgdal.so.33
}

do_install() {
    install -d ${D}${libdir}
    install -m 0755 libgdal.so.33 ${D}${libdir}/libgdal.so.33
    ln -sf libgdal.so.33 ${D}${libdir}/libgdal.so
}

FILES:${PN} = "${libdir}/libgdal.so.33"
FILES:${PN}-dev = "${libdir}/libgdal.so"

INSANE_SKIP:${PN} += "ldflags"
ALLOW_EMPTY:${PN} = "1"
