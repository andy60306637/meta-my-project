#!/bin/bash
# IMX219 Camera to DisplayPort Test Script
# Test camera detection and display output

set -e

echo "======================================"
echo "IMX219 Camera to DisplayPort Test"
echo "======================================"
echo ""

# Check if running as root (needed for some operations)
if [ "$EUID" -ne 0 ]; then 
    echo "WARNING: Some tests require root privileges"
    echo "Run with sudo for full functionality"
    echo ""
fi

# Test 1: Check DisplayPort connection
echo "1. Checking DisplayPort/HDMI connection..."
if [ -d /sys/class/drm/card0-DP-1 ]; then
    DP_STATUS=$(cat /sys/class/drm/card0-DP-1/status 2>/dev/null || echo "unknown")
    echo "   DisplayPort-1: $DP_STATUS"
    if [ "$DP_STATUS" = "connected" ]; then
        echo "   ✓ DisplayPort is connected"
    else
        echo "   ✗ DisplayPort not connected"
        echo "   Please connect a DisplayPort/HDMI monitor"
    fi
else
    echo "   Checking HDMI connection..."
    if [ -d /sys/class/drm/card0-HDMI-A-1 ]; then
        HDMI_STATUS=$(cat /sys/class/drm/card0-HDMI-A-1/status 2>/dev/null || echo "unknown")
        echo "   HDMI: $HDMI_STATUS"
    fi
fi
echo ""

# Test 2: Check nvidia-drm module
echo "2. Checking nvidia-drm module..."
if lsmod | grep -q nvidia_drm; then
    echo "   ✓ nvidia-drm module loaded"
    MODESET=$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null || echo "N")
    FBDEV=$(cat /sys/module/nvidia_drm/parameters/fbdev 2>/dev/null || echo "N")
    echo "   - modeset: $MODESET"
    echo "   - fbdev: $FBDEV"
    if [ "$MODESET" = "Y" ]; then
        echo "   ✓ KMS mode enabled"
    else
        echo "   ✗ KMS mode disabled"
    fi
else
    echo "   ✗ nvidia-drm module not loaded"
fi
echo ""

# Test 3: Check DRM devices
echo "3. Checking DRM devices..."
if [ -c /dev/dri/card0 ]; then
    echo "   ✓ /dev/dri/card0 exists"
    ls -l /dev/dri/
else
    echo "   ✗ /dev/dri/card0 not found"
fi
echo ""

# Test 4: Check V4L2 camera devices
echo "4. Checking V4L2 camera devices..."
if [ -c /dev/video0 ]; then
    echo "   ✓ /dev/video0 exists"
    v4l2-ctl --list-devices 2>/dev/null || echo "   (v4l2-ctl not available)"
else
    echo "   ✗ /dev/video0 not found"
    echo "   Camera may not be detected"
fi
echo ""

# Test 5: Check I2C camera detection
echo "5. Checking I2C camera detection (IMX219 on bus 7)..."
if command -v i2cdetect >/dev/null 2>&1; then
    if [ "$EUID" -eq 0 ]; then
        echo "   I2C bus 7 scan:"
        i2cdetect -y -r 7 2>/dev/null | grep -A 10 "0  1  2" || echo "   (scan failed)"
        if i2cdetect -y -r 7 2>/dev/null | grep -q "10"; then
            echo "   ✓ IMX219 detected at address 0x10"
        else
            echo "   ✗ IMX219 not detected at 0x10"
        fi
    else
        echo "   (requires root - skipped)"
    fi
else
    echo "   (i2cdetect not available)"
fi
echo ""

# Test 6: Check argus daemon
echo "6. Checking argus daemon..."
if systemctl is-active --quiet nvargus-daemon 2>/dev/null; then
    echo "   ✓ nvargus-daemon is running"
elif pgrep -x nvargus-daemon >/dev/null; then
    echo "   ✓ nvargus-daemon is running (not via systemd)"
else
    echo "   ✗ nvargus-daemon not running"
    echo "   Try: systemctl start nvargus-daemon"
fi
echo ""

# Test 7: Check GStreamer plugins
echo "7. Checking GStreamer plugins..."
if command -v gst-inspect-1.0 >/dev/null 2>&1; then
    if gst-inspect-1.0 nvarguscamerasrc >/dev/null 2>&1; then
        echo "   ✓ nvarguscamerasrc available"
    else
        echo "   ✗ nvarguscamerasrc not found"
    fi
    if gst-inspect-1.0 nvoverlaysink >/dev/null 2>&1; then
        echo "   ✓ nvoverlaysink available"
    else
        echo "   ✗ nvoverlaysink not found"
    fi
    if gst-inspect-1.0 waylandsink >/dev/null 2>&1; then
        echo "   ✓ waylandsink available"
    else
        echo "   ✗ waylandsink not found"
    fi
else
    echo "   (gst-inspect-1.0 not available)"
fi
echo ""

# Test 8: Display environment
echo "8. Checking display environment..."
if [ -n "$DISPLAY" ]; then
    echo "   DISPLAY=$DISPLAY"
elif [ -n "$WAYLAND_DISPLAY" ]; then
    echo "   WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
else
    echo "   No X11 or Wayland display detected"
    echo "   For console mode, use nvoverlaysink"
fi
echo ""

echo "======================================"
echo "Test Complete"
echo "======================================"
echo ""
echo "To test camera preview, run:"
echo "  camera-preview.sh"
echo ""
echo "To record video, run:"
echo "  camera-record.sh <output-file.mp4>"
