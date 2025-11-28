#!/bin/bash
# IMX219 Camera Kiosk Mode
# Automatically display camera fullscreen on boot

# Wait for Wayland to be ready
for i in {1..30}; do
    if [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
        echo "Wayland display ready"
        break
    fi
    echo "Waiting for Wayland display... ($i/30)"
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
echo "Display: $WAYLAND_DISPLAY"
echo ""

# Launch fullscreen camera display
# Using waylandsink in fullscreen mode
exec gst-launch-1.0 -v \
    nvarguscamerasrc sensor-id=$SENSOR_ID ! \
    "video/x-raw(memory:NVMM),width=$WIDTH,height=$HEIGHT,framerate=$FRAMERATE/1" ! \
    nvvidconv ! \
    "video/x-raw,format=RGBA" ! \
    waylandsink fullscreen=true sync=false
