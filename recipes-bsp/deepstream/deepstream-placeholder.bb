SUMMARY = "NVIDIA DeepStream SDK for Jetson"
DESCRIPTION = "NVIDIA DeepStream SDK is a complete streaming analytics toolkit for AI-based video understanding"
LICENSE = "CLOSED"

# DeepStream is typically installed via NVIDIA package manager or manually
# This is a placeholder recipe that documents the dependency

# For Yocto integration, you have two options:
# 1. Use NVIDIA's pre-built DeepStream packages (recommended)
# 2. Build DeepStream from source (complex)

# This recipe creates a dummy package that marks DeepStream as satisfied
# when it's pre-installed in the rootfs

ALLOW_EMPTY:${PN} = "1"

do_install() {
    # Create marker directory
    install -d ${D}/opt/nvidia/deepstream
}

FILES:${PN} = "/opt/nvidia/deepstream"

# Mark as provided so recipes can depend on it
PROVIDES = "deepstream"
RPROVIDES:${PN} = "deepstream"

INSANE_SKIP:${PN} += "installed-vs-shipped"
