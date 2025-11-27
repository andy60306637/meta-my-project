#!/bin/bash
# IMX219 Camera Recording Script
# Record video from IMX219 camera

set -e

SENSOR_ID=0
WIDTH=1920
HEIGHT=1080
FRAMERATE=30
BITRATE=8000000
OUTPUT_FILE=""

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
        --bitrate)
            BITRATE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 <output-file> [options]"
            echo ""
            echo "Arguments:"
            echo "  <output-file>     Output video file (required)"
            echo ""
            echo "Options:"
            echo "  --sensor <id>     Camera sensor ID (default: 0)"
            echo "  --width <pixels>  Video width (default: 1920)"
            echo "  --height <pixels> Video height (default: 1080)"
            echo "  --fps <rate>      Frame rate (default: 30)"
            echo "  --bitrate <bps>   Bitrate in bps (default: 8000000)"
            echo ""
            echo "Examples:"
            echo "  $0 video.mp4"
            echo "  $0 video.mp4 --width 1280 --height 720 --fps 60"
            echo "  $0 video.h264 --bitrate 10000000"
            echo ""
            echo "Press Ctrl+C to stop recording"
            exit 0
            ;;
        *)
            if [ -z "$OUTPUT_FILE" ]; then
                OUTPUT_FILE="$1"
                shift
            else
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
            fi
            ;;
    esac
done

if [ -z "$OUTPUT_FILE" ]; then
    echo "ERROR: Output file not specified"
    echo "Usage: $0 <output-file> [options]"
    echo "Use --help for more information"
    exit 1
fi

echo "======================================"
echo "IMX219 Camera Recording"
echo "======================================"
echo "Sensor ID: $SENSOR_ID"
echo "Resolution: ${WIDTH}x${HEIGHT}"
echo "Frame Rate: ${FRAMERATE} fps"
echo "Bitrate: $BITRATE bps"
echo "Output File: $OUTPUT_FILE"
echo ""
echo "Press Ctrl+C to stop recording"
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

# Record video with hardware encoding
gst-launch-1.0 -e \
    nvarguscamerasrc sensor-id=$SENSOR_ID ! \
    "video/x-raw(memory:NVMM),width=$WIDTH,height=$HEIGHT,framerate=$FRAMERATE/1" ! \
    nvv4l2h264enc bitrate=$BITRATE ! \
    h264parse ! \
    qtmux ! \
    filesink location="$OUTPUT_FILE"

echo ""
echo "Recording saved to: $OUTPUT_FILE"
