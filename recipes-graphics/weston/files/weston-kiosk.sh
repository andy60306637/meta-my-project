#!/bin/bash
# Weston Kiosk Mode Startup Script

export XDG_RUNTIME_DIR=/run/user/0
export WAYLAND_DISPLAY=wayland-0

# Ensure runtime directory exists
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

echo "Starting Weston compositor for kiosk mode..."
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"

# Wait for DRM device
for i in {1..10}; do
    if [ -e /dev/dri/card0 ]; then
        echo "DRM device ready"
        break
    fi
    echo "Waiting for DRM device... ($i/10)"
    sleep 1
done

# Start Weston with DRM backend
# Using GL renderer for better performance (NVIDIA GPU acceleration)
exec weston \
    --backend=drm-backend.so \
    --log=/var/log/weston.log \
    --idle-time=0
