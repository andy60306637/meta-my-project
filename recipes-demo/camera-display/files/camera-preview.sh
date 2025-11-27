#!/bin/bash
# IMX219 Camera Preview Script
# Display camera output directly to DisplayPort/HDMI

# Don't exit on error - we want to try multiple methods
set +e

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

# Try different video sinks in order of preference
# Method 1: nv3dsink (NVIDIA EGL sink for direct rendering)
if gst-inspect-1.0 nv3dsink >/dev/null 2>&1; then
    echo "Trying nv3dsink..."
    if gst-launch-1.0 -v \
        nvarguscamerasrc sensor-id=$SENSOR_ID ! \
        "video/x-raw(memory:NVMM),width=$WIDTH,height=$HEIGHT,framerate=$FRAMERATE/1" ! \
        nv3dsink sync=false 2>&1; then
        exit 0
    fi
    echo "nv3dsink failed, trying next option..."
    echo ""
fi

# Method 2: nvoverlaysink (direct to framebuffer)
if gst-inspect-1.0 nvoverlaysink >/dev/null 2>&1; then
    echo "Trying nvoverlaysink..."
    if gst-launch-1.0 -v \
        nvarguscamerasrc sensor-id=$SENSOR_ID ! \
        "video/x-raw(memory:NVMM),width=$WIDTH,height=$HEIGHT,framerate=$FRAMERATE/1" ! \
        nvoverlaysink sync=false 2>&1; then
        exit 0
    fi
    echo "nvoverlaysink failed, trying next option..."
    echo ""
fi

# Method 3: waylandsink (requires Wayland compositor)
if gst-inspect-1.0 waylandsink >/dev/null 2>&1; then
    echo "Trying waylandsink (requires Wayland compositor)..."
    if gst-launch-1.0 -v \
        nvarguscamerasrc sensor-id=$SENSOR_ID ! \
        "video/x-raw(memory:NVMM),width=$WIDTH,height=$HEIGHT,framerate=$FRAMERATE/1" ! \
        nvvidconv ! \
        "video/x-raw,format=RGBA" ! \
        waylandsink sync=false 2>&1; then
        exit 0
    fi
    echo "waylandsink failed, trying next option..."
    echo ""
fi

# Method 4: kmssink (direct KMS/DRM output)
if gst-inspect-1.0 kmssink >/dev/null 2>&1; then
    echo "Trying kmssink (direct DRM/KMS output)..."
    if gst-launch-1.0 -v \
        nvarguscamerasrc sensor-id=$SENSOR_ID ! \
        "video/x-raw(memory:NVMM),width=$WIDTH,height=$HEIGHT,framerate=$FRAMERATE/1" ! \
        nvvidconv ! \
        "video/x-raw,format=RGBA" ! \
        kmssink connector-id=37 plane-id=1 sync=false 2>&1; then
        exit 0
    fi
    echo "kmssink failed, trying next option..."
    echo ""
fi

# Method 5: autovideosink (automatic selection)
echo "Trying autovideosink (automatic sink selection)..."
gst-launch-1.0 -v \
    nvarguscamerasrc sensor-id=$SENSOR_ID ! \
    "video/x-raw(memory:NVMM),width=$WIDTH,height=$HEIGHT,framerate=$FRAMERATE/1" ! \
    nvvidconv ! \
    "video/x-raw,format=RGBA" ! \
    autovideosink sync=false

# Check exit code
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ] || [ $EXIT_CODE -eq 130 ]; then
    # Exit code 0 = success, 130 = interrupted by Ctrl+C (which is normal)
    echo ""
    echo "Camera preview stopped."
    exit 0
fi

echo ""
echo "All video sink methods failed."
echo "Please check:"
echo "  1. Display is connected to DisplayPort/HDMI"
echo "  2. Display environment (X11/Wayland) is running"
echo "  3. Run 'gst-inspect-1.0 | grep sink' to see available sinks"
exit 1
