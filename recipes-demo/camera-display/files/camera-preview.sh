#!/bin/bash
# IMX219 Camera Preview Script
# Display camera output directly to DisplayPort/HDMI

set -e

SENSOR_ID=0
WIDTH=1920
HEIGHT=1080
FRAMERATE=30

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sensor)
            SENSOR_ID="$2"
            shift 2
            ;;
        --width)
            WIDTH="$2"
            shift 2
            ;;
        --height)
            HEIGHT="$2"
            shift 2
            ;;
        --fps)
            FRAMERATE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --sensor <id>     Camera sensor ID (default: 0)"
            echo "  --width <pixels>  Video width (default: 1920)"
            echo "  --height <pixels> Video height (default: 1080)"
            echo "  --fps <rate>      Frame rate (default: 30)"
            echo ""
            echo "Examples:"
            echo "  $0                           # Full HD 1080p preview"
            echo "  $0 --width 1280 --height 720 # HD 720p preview"
            echo "  $0 --width 640 --height 480  # VGA preview"
            echo ""
            echo "Press Ctrl+C to stop preview"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "======================================"
echo "IMX219 Camera Preview"
echo "======================================"
echo "Sensor ID: $SENSOR_ID"
echo "Resolution: ${WIDTH}x${HEIGHT}"
echo "Frame Rate: ${FRAMERATE} fps"
echo ""
echo "Press Ctrl+C to stop"
echo "======================================"
echo ""

# Check if argus daemon is running
if ! pgrep -x nvargus-daemon >/dev/null; then
    echo "WARNING: nvargus-daemon not running"
    echo "Starting nvargus-daemon..."
    if [ "$EUID" -eq 0 ]; then
        systemctl start nvargus-daemon || /usr/sbin/nvargus-daemon &
        sleep 2
    else
        echo "ERROR: nvargus-daemon requires root to start"
        echo "Run: sudo systemctl start nvargus-daemon"
        exit 1
    fi
fi

# Method 1: Try nvoverlaysink (direct to framebuffer, works without X11/Wayland)
echo "Attempting camera preview with nvoverlaysink..."
gst-launch-1.0 -v \
    nvarguscamerasrc sensor-id=$SENSOR_ID ! \
    "video/x-raw(memory:NVMM),width=$WIDTH,height=$HEIGHT,framerate=$FRAMERATE/1" ! \
    nvoverlaysink sync=false

# If nvoverlaysink fails and Wayland is available, try waylandsink
# if [ -n "$WAYLAND_DISPLAY" ]; then
#     echo "Trying waylandsink..."
#     gst-launch-1.0 -v \
#         nvarguscamerasrc sensor-id=$SENSOR_ID ! \
#         "video/x-raw(memory:NVMM),width=$WIDTH,height=$HEIGHT,framerate=$FRAMERATE/1" ! \
#         nvvidconv ! \
#         "video/x-raw,format=I420" ! \
#         waylandsink sync=false
# fi
