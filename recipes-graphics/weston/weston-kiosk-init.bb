SUMMARY = "Weston compositor auto-start for kiosk mode"
DESCRIPTION = "Systemd service to automatically start Weston for camera kiosk application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://weston-kiosk.service \
    file://weston-kiosk.sh \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "weston-kiosk.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} = "weston bash"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/weston-kiosk.service ${D}${systemd_system_unitdir}
    
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/weston-kiosk.sh ${D}${bindir}
}

FILES:${PN} = "${systemd_system_unitdir}/weston-kiosk.service ${bindir}/weston-kiosk.sh"
