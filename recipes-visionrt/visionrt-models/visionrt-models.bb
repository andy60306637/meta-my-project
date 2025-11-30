SUMMARY = "VisionRT AI Models and Configuration Files"
DESCRIPTION = "AI models, labels, and configuration files for VisionRT application"
LICENSE = "CLOSED"

# Fetch models and labels from VisionRT repository
SRC_URI = " \
    file://models/resnet18_trafficcamnet_pruned.onnx \
    file://models/trafficcamnet_labels.txt \
    file://models/labels.txt \
    file://data/labels.txt \
"

S = "${WORKDIR}"

do_install() {
    # Install AI models
    install -d ${D}/opt/nvidia/deepstream/models/visionrt
    install -m 0644 ${WORKDIR}/models/resnet18_trafficcamnet_pruned.onnx \
        ${D}/opt/nvidia/deepstream/models/visionrt/
    
    # Install labels
    install -m 0644 ${WORKDIR}/models/trafficcamnet_labels.txt \
        ${D}/opt/nvidia/deepstream/models/visionrt/
    install -m 0644 ${WORKDIR}/models/labels.txt \
        ${D}/opt/nvidia/deepstream/models/visionrt/
    
    # Also install to /etc/visionrt for easy access
    install -d ${D}${sysconfdir}/visionrt/models
    install -m 0644 ${WORKDIR}/models/*.txt ${D}${sysconfdir}/visionrt/models/
    install -m 0644 ${WORKDIR}/data/labels.txt ${D}${sysconfdir}/visionrt/models/data_labels.txt
    
    # Create symlinks in /etc/visionrt for models
    ln -sf /opt/nvidia/deepstream/models/visionrt/resnet18_trafficcamnet_pruned.onnx \
        ${D}${sysconfdir}/visionrt/models/primary_model.onnx
}

FILES:${PN} = " \
    /opt/nvidia/deepstream/models/visionrt/* \
    ${sysconfdir}/visionrt/models/* \
"

INSANE_SKIP:${PN} += "already-stripped"
