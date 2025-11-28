#!/bin/bash
# IMX219 Camera Kiosk Mode
# Direct hardware output to DisplayPort without compositor

# Wait for DRM device to be ready
for i in {1..10}; do
    if [ -e /dev/dri/card0 ]; then
        echo "DRM device ready"
        break
    fi
    echo "Waiting for DRM device... ($i/10)"
    sleep 1
done

# Wait for camera to be ready
for i in {1..10}; do
    if [ -c /dev/video0 ]; then
        echo "Camera device ready"
        break
    fi
    echo "Waiting for camera... ($i/10)"
    sleep 1
done

# Configuration
SENSOR_ID=0
WIDTH=1920
HEIGHT=1080
FRAMERATE=30

echo "======================================"
echo "Starting Camera Kiosk Mode"
echo "======================================"
echo "Resolution: ${WIDTH}x${HEIGHT} @ ${FRAMERATE}fps"
echo "Output: Direct to DisplayPort via nvdrmvideosink"
echo ""

# Launch fullscreen camera display
# Direct hardware output using nvdrmvideosink (no compositor needed)
exec gst-launch-1.0 -v \
    nvarguscamerasrc sensor-id=$SENSOR_ID ! \
    "video/x-raw(memory:NVMM),width=$WIDTH,height=$HEIGHT,framerate=$FRAMERATE/1" ! \
    nvvidconv ! \
    "video/x-raw(memory:NVMM)" ! \
    nvdrmvideosink
