SUMMARY = "VisionRT - AI Vision Processing Application with DeepStream"
DESCRIPTION = "A GStreamer-based AI vision processing application for Jetson Orin Nano \
that integrates NVIDIA DeepStream for real-time object detection and tracking."
LICENSE = "CLOSED"

DEPENDS = " \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    opencv \
    gdal-stub \
    cuda-toolkit \
    cuda-cudart \
    cudnn \
    tensorrt-core \
    deepstream-7.1 \
"

# Runtime dependencies
RDEPENDS:${PN} = " \
    gstreamer1.0 \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    opencv \
    cuda-toolkit \
    cudnn \
    tensorrt-core \
    deepstream-7.1 \
    visionrt-models \
"

# Fetch from local VisionRT git repository
SRC_URI = " \
    git:///${TOPDIR}/../../VisionRT;protocol=file;branch=master \
"

# Use latest commit
SRCREV = "${AUTOREV}"
PV = "1.0+git${SRCPV}"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

inherit cmake pkgconfig

# DeepStream and CUDA paths in target rootfs
DEEPSTREAM_DIR = "${STAGING_DIR_TARGET}/opt/nvidia/deepstream/deepstream-7.1"
CUDA_DIR = "${STAGING_DIR_TARGET}/usr/local/cuda-12.6"

EXTRA_OECMAKE = " \
    -DCMAKE_BUILD_TYPE=Release \
    -DDEEPSTREAM_DIR=${DEEPSTREAM_DIR} \
    -DCUDA_DIR=${CUDA_DIR} \
    -DCMAKE_SKIP_RPATH=ON \
    -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_DIR} \
    -DCUDAToolkit_ROOT=${CUDA_DIR} \
    -DCUDA_INCLUDE_DIRS=${CUDA_DIR}/include \
    -DCMAKE_EXE_LINKER_FLAGS='-Wl,--unresolved-symbols=ignore-in-shared-libs' \
"

# Ensure we can find CUDA and DeepStream headers during configuration
EXTRA_OECMAKE:append = " \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
    -DCMAKE_CXX_FLAGS='${CXXFLAGS} -I${STAGING_DIR_TARGET}/usr/local/cuda-12.6/include' \
    -DCMAKE_C_FLAGS='${CFLAGS} -I${STAGING_DIR_TARGET}/usr/local/cuda-12.6/include' \
"

do_configure:prepend() {
    # Ensure build directory exists
    install -d ${B}
}

do_install() {
    # Install the main executable
    install -d ${D}${bindir}
    if [ -f ${B}/src/mjpeg_streamer ]; then
        install -m 0755 ${B}/src/mjpeg_streamer ${D}${bindir}/visionrt
    else
        bbfatal "mjpeg_streamer executable not found in ${B}/src/"
    fi
    
    # Install the custom bbox parser library (check multiple possible locations)
    # This is a DeepStream plugin, so it goes into ${libdir}
    install -d ${D}${libdir}
    if [ -f ${B}/libnvdsinfer_custombboxparser.so ]; then
        # Install as versioned library with symlink to satisfy QA
        install -m 0755 ${B}/libnvdsinfer_custombboxparser.so ${D}${libdir}/libnvdsinfer_custombboxparser.so.1.0
        ln -sf libnvdsinfer_custombboxparser.so.1.0 ${D}${libdir}/libnvdsinfer_custombboxparser.so
    elif [ -f ${B}/lib/libnvdsinfer_custombboxparser.so ]; then
        install -m 0755 ${B}/lib/libnvdsinfer_custombboxparser.so ${D}${libdir}/libnvdsinfer_custombboxparser.so.1.0
        ln -sf libnvdsinfer_custombboxparser.so.1.0 ${D}${libdir}/libnvdsinfer_custombboxparser.so
    else
        bbwarn "libnvdsinfer_custombboxparser.so not found, skipping installation"
    fi
    
    # Install configuration files with path corrections
    install -d ${D}${sysconfdir}/visionrt
    
    # Fix paths in config_infer_primary.txt
    sed -e 's|/home/andy/Desktop/project/test/models/|/opt/nvidia/deepstream/models/visionrt/|g' \
        ${S}/configs/config_infer_primary.txt > ${D}${sysconfdir}/visionrt/config_infer_primary.txt
    chmod 0644 ${D}${sysconfdir}/visionrt/config_infer_primary.txt
    
    # Install other configs as-is
    install -m 0644 ${S}/configs/nvinfer_config.txt ${D}${sysconfdir}/visionrt/
    install -m 0644 ${S}/configs/simple_config.txt ${D}${sysconfdir}/visionrt/
    
    # Install systemd service
    install -d ${D}${systemd_system_unitdir}
    cat > ${D}${systemd_system_unitdir}/visionrt.service << 'EOF'
[Unit]
Description=VisionRT AI Vision Processing Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/visionrt
WorkingDirectory=/etc/visionrt
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
User=root
Environment="LD_LIBRARY_PATH=/usr/lib:/opt/nvidia/deepstream/deepstream/lib"
Environment="VISIONRT_CONFIG_PATH=/etc/visionrt/config_infer_primary.txt"

[Install]
WantedBy=multi-user.target
EOF
}

FILES:${PN} = " \
    ${bindir}/visionrt \
    ${libdir}/libnvdsinfer_custombboxparser.so.* \
    ${sysconfdir}/visionrt/* \
    ${systemd_system_unitdir}/visionrt.service \
"

FILES:${PN}-dev = " \
    ${libdir}/libnvdsinfer_custombboxparser.so \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "visionrt.service"
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

# Allow commercial license for DeepStream and CUDA
LICENSE_FLAGS_ACCEPTED = "commercial"

INSANE_SKIP:${PN} += "dev-so ldflags"
