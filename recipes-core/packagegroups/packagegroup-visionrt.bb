SUMMARY = "VisionRT Application Package Group"
DESCRIPTION = "Package group for VisionRT AI vision processing application and its dependencies"

inherit packagegroup

RDEPENDS:${PN} = " \
    visionrt \
    visionrt-models \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    opencv \
"

# Optional packages - won't fail if not available
RDEPENDS:${PN}:append = " \
    ${@bb.utils.contains('BBFILE_COLLECTIONS', 'tegra', 'tegra-nvpmodel', '', d)} \
"
