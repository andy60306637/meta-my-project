SUMMARY = "IMX219 Camera to DisplayPort test scripts"
DESCRIPTION = "Scripts to test IMX219 camera output to DisplayPort/HDMI"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://camera-display-test.sh \
    file://camera-preview.sh \
    file://camera-record.sh \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/camera-display-test.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/camera-preview.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/camera-record.sh ${D}${bindir}/
}

FILES:${PN} = "${bindir}/*"

RDEPENDS:${PN} = "gstreamer1.0-plugins-tegra tegra-argus-daemon v4l-utils bash"
