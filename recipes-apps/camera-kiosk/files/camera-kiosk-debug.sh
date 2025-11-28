#!/bin/bash
# Camera Kiosk Debug Script
# 用於診斷為什麼相機畫面沒有顯示

echo "========================================"
echo "Camera Kiosk Mode - Debug Information"
echo "========================================"
echo ""

# 1. 檢查 systemd 服務狀態
echo "=== 1. Systemd Services Status ==="
echo ""
echo "--- weston-kiosk.service ---"
systemctl status weston-kiosk --no-pager
echo ""
echo "--- nvargus-daemon.service ---"
systemctl status nvargus-daemon --no-pager
echo ""
echo "--- camera-kiosk.service ---"
systemctl status camera-kiosk --no-pager
echo ""

# 2. 檢查服務是否啟用
echo "=== 2. Service Enable Status ==="
systemctl is-enabled weston-kiosk
systemctl is-enabled nvargus-daemon
systemctl is-enabled camera-kiosk
echo ""

# 3. 檢查 Wayland socket
echo "=== 3. Wayland Socket ==="
echo "XDG_RUNTIME_DIR=/run/user/0"
ls -la /run/user/0/ 2>/dev/null || echo "Directory /run/user/0 does not exist!"
echo ""
if [ -S /run/user/0/wayland-0 ]; then
    echo "✓ Wayland socket exists"
else
    echo "✗ Wayland socket NOT found!"
fi
echo ""

# 4. 檢查相機裝置
echo "=== 4. Camera Device ==="
ls -l /dev/video* 2>/dev/null || echo "No video devices found!"
echo ""
echo "I2C Camera Detection (bus 7):"
i2cdetect -y 7 2>/dev/null || echo "i2cdetect failed"
echo ""

# 5. 檢查 DRM 裝置
echo "=== 5. DRM Devices ==="
ls -la /dev/dri/
echo ""
lsmod | grep -E "nvidia|drm"
echo ""

# 6. 檢查 DisplayPort 連接
echo "=== 6. Display Connection ==="
modetest -M tegra-udrm -c 2>/dev/null | head -30 || echo "modetest failed"
echo ""

# 7. 檢查 Weston 程序
echo "=== 7. Weston Process ==="
ps aux | grep -E "[w]eston|[g]st-launch" | head -10
echo ""

# 8. 查看最近的日誌
echo "=== 8. Recent Logs (last 2 minutes) ==="
echo ""
echo "--- Weston logs ---"
journalctl -u weston-kiosk --since "2 minutes ago" --no-pager | tail -20
echo ""
echo "--- Camera kiosk logs ---"
journalctl -u camera-kiosk --since "2 minutes ago" --no-pager | tail -20
echo ""
echo "--- Argus daemon logs ---"
journalctl -u nvargus-daemon --since "2 minutes ago" --no-pager | tail -20
echo ""

# 9. 檢查 Weston 日誌檔案
echo "=== 9. Weston Log File ==="
if [ -f /var/log/weston.log ]; then
    echo "Last 30 lines of /var/log/weston.log:"
    tail -30 /var/log/weston.log
else
    echo "Weston log file not found at /var/log/weston.log"
fi
echo ""

# 10. 檢查 kernel messages
echo "=== 10. Kernel Messages (DRM/Display) ==="
dmesg | grep -iE "drm|nvidia|display|dp" | tail -20
echo ""

# 11. 環境變數檢查
echo "=== 11. Environment Variables ==="
echo "Current user: $(whoami)"
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
echo "DISPLAY: $DISPLAY"
echo ""

# 12. 測試建議
echo "========================================"
echo "Debug Summary & Next Steps"
echo "========================================"
echo ""
echo "如果上述資訊顯示:"
echo ""
echo "問題 1: weston-kiosk.service 失敗"
echo "  解決: journalctl -u weston-kiosk -n 50"
echo "  手動測試: systemctl restart weston-kiosk"
echo ""
echo "問題 2: camera-kiosk.service 一直等待 Wayland"
echo "  解決: 先確保 weston-kiosk 正常運作"
echo "  檢查: ls -la /run/user/0/wayland-0"
echo ""
echo "問題 3: 相機裝置不存在 (/dev/video0)"
echo "  解決: 檢查硬體連接"
echo "  確認: i2cdetect -y 7 應該看到 0x10"
echo ""
echo "問題 4: DisplayPort 沒有連接"
echo "  解決: 檢查顯示器連接和電源"
echo "  確認: modetest -M tegra-udrm -c 應該看到 connected"
echo ""
echo "手動測試相機管線:"
echo "  export XDG_RUNTIME_DIR=/run/user/0"
echo "  export WAYLAND_DISPLAY=wayland-0"
echo "  gst-launch-1.0 nvarguscamerasrc sensor-id=0 num-buffers=100 ! fakesink"
echo ""
echo "完整除錯輸出已儲存,請執行:"
echo "  bash /usr/bin/camera-kiosk-debug.sh > /tmp/debug-output.txt 2>&1"
echo "  cat /tmp/debug-output.txt"
echo ""
