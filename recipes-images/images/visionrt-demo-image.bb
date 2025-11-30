SUMMARY = "Demo image with VisionRT AI vision processing"
DESCRIPTION = "Tegra demo image based on demo-image-egl with VisionRT application, \
IMX219 camera support, and DisplayPort output capabilities"

LICENSE = "MIT"

# Inherit from demo-image-egl to get all the proven configurations
require recipes-demo/images/demo-image-egl.bb

# Add VisionRT package group
CORE_IMAGE_BASE_INSTALL += "packagegroup-visionrt"

# Add NFS support for development
CORE_IMAGE_BASE_INSTALL += "nfs-utils nfs-utils-client"

# Add package management for on-device updates
IMAGE_FEATURES += "package-management"
