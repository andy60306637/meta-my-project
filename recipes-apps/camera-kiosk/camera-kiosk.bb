SUMMARY = "IMX219 Camera Kiosk Mode - Direct DisplayPort Output"
DESCRIPTION = "Systemd service to automatically display IMX219 camera via direct hardware output on boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://camera-kiosk.service \
    file://camera-kiosk.sh \
    file://camera-kiosk-debug.sh \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "camera-kiosk.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/camera-kiosk.service ${D}${systemd_system_unitdir}/
    
    # Install startup script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/camera-kiosk.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/camera-kiosk-debug.sh ${D}${bindir}/
}

FILES:${PN} = " \
    ${systemd_system_unitdir}/camera-kiosk.service \
    ${bindir}/camera-kiosk.sh \
    ${bindir}/camera-kiosk-debug.sh \
"

RDEPENDS:${PN} = "gstreamer1.0-plugins-tegra gstreamer1.0-plugins-nvvideosinks bash"
