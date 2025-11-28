# Camera Kiosk Mode

## 概述

Camera Kiosk Mode 是一個自動啟動的服務,讓 Jetson Orin Nano 在開機後自動顯示 IMX219 鏡頭的即時畫面到 DisplayPort 輸出。這個模式適合用於產品展示、監控系統、或任何需要開機即顯示鏡頭畫面的應用場景。

## 功能特性

- ✅ **自動啟動**: 系統開機後自動啟動相機顯示
- ✅ **全螢幕顯示**: 相機畫面以全螢幕模式顯示於 DisplayPort
- ✅ **無需互動**: 無需任何使用者操作,開機即可運作
- ✅ **自動重啟**: 服務異常時自動重啟
- ✅ **相依性管理**: 等待 Weston 和 nvargus-daemon 就緒後才啟動

## 系統需求

### 硬體需求
- Jetson Orin Nano 4GB (P3767-0004)
- IMX219 相機模組連接至 CAM1 (CSI-C)
- DisplayPort 顯示器連接

### 軟體需求
- Yocto scarthgap (5.0)
- meta-tegra L4T R36.4.4
- Weston Wayland compositor
- GStreamer 1.22+ with NVIDIA plugins

## 使用方式

### 基本操作

#### 1. 檢查服務狀態
```bash
systemctl status camera-kiosk
```

預期輸出:
```
● camera-kiosk.service - Camera Kiosk Mode - Automatic Fullscreen Camera Display
     Loaded: loaded (/lib/systemd/system/camera-kiosk.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2024-01-XX XX:XX:XX UTC; 1min 23s ago
   Main PID: 1234 (camera-kiosk.sh)
      Tasks: 12 (limit: 4449)
     Memory: 45.3M
        CPU: 2.145s
     CGroup: /system.slice/camera-kiosk.service
             ├─1234 /bin/bash /usr/bin/camera-kiosk.sh
             └─1235 gst-launch-1.0 nvarguscamerasrc ...
```

#### 2. 停止服務
```bash
sudo systemctl stop camera-kiosk
```

#### 3. 啟動服務
```bash
sudo systemctl start camera-kiosk
```

#### 4. 重新啟動服務
```bash
sudo systemctl restart camera-kiosk
```

#### 5. 停用自動啟動
```bash
sudo systemctl disable camera-kiosk
```

#### 6. 啟用自動啟動
```bash
sudo systemctl enable camera-kiosk
```

### 進階操作

#### 查看服務日誌
```bash
# 查看最近的日誌
sudo journalctl -u camera-kiosk -n 50

# 即時追蹤日誌
sudo journalctl -u camera-kiosk -f

# 查看今天的日誌
sudo journalctl -u camera-kiosk --since today
```

#### 查看 GStreamer 管線狀態
```bash
# 找出 GStreamer 程序
ps aux | grep gst-launch

# 查看 GStreamer 除錯資訊
sudo systemctl stop camera-kiosk
GST_DEBUG=3 /usr/bin/camera-kiosk.sh
```

## 設定檔位置

### 服務檔案
- **Systemd 服務**: `/lib/systemd/system/camera-kiosk.service`
- **啟動腳本**: `/usr/bin/camera-kiosk.sh`

### 腳本內容
```bash
#!/bin/bash

# 等待 Wayland socket 就緒
echo "等待 Wayland 顯示伺服器..."
timeout=30
while [ $timeout -gt 0 ] && [ ! -S "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}" ]; do
    sleep 1
    timeout=$((timeout - 1))
done

# 等待相機裝置就緒
echo "等待相機裝置..."
timeout=10
while [ $timeout -gt 0 ] && [ ! -e "/dev/video0" ]; do
    sleep 1
    timeout=$((timeout - 1))
done

# 啟動全螢幕相機顯示
echo "啟動相機 kiosk 模式..."
gst-launch-1.0 \
    nvarguscamerasrc \
    ! "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1" \
    ! nvvidconv \
    ! waylandsink fullscreen=true sync=false
```

## 自訂設定

### 修改解析度和幀率

編輯 `/usr/bin/camera-kiosk.sh`:

```bash
# 修改為 4K @ 15fps
gst-launch-1.0 \
    nvarguscamerasrc \
    ! "video/x-raw(memory:NVMM),width=3840,height=2160,framerate=15/1" \
    ! nvvidconv \
    ! waylandsink fullscreen=true sync=false
```

支援的解析度:
- 1920x1080 @ 30fps (預設)
- 1280x720 @ 60fps
- 3264x2464 @ 21fps (最大解析度)
- 3840x2160 @ 15fps (4K)

### 新增時間戳記顯示

編輯啟動腳本,在管線中加入 `textoverlay`:

```bash
gst-launch-1.0 \
    nvarguscamerasrc \
    ! "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1" \
    ! nvvidconv \
    ! "video/x-raw,format=RGBA" \
    ! textoverlay text="Camera Live" valignment=top halignment=left font-desc="Sans, 24" \
    ! waylandsink fullscreen=true sync=false
```

### 新增錄影功能(雙路輸出)

同時顯示和錄影:

```bash
gst-launch-1.0 \
    nvarguscamerasrc \
    ! "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1" \
    ! tee name=t \
    t. ! queue ! nvvidconv ! waylandsink fullscreen=true sync=false \
    t. ! queue ! nvv4l2h265enc ! h265parse ! matroskamux ! filesink location=/tmp/recording.mkv
```

### 使用多個相機

如果有多個相機,可以指定 sensor-id:

```bash
# 使用 CAM0 (sensor-id=0)
gst-launch-1.0 \
    nvarguscamerasrc sensor-id=0 \
    ! "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1" \
    ! nvvidconv \
    ! waylandsink fullscreen=true sync=false

# 使用 CAM1 (sensor-id=1, 預設)
gst-launch-1.0 \
    nvarguscamerasrc sensor-id=1 \
    ! "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1" \
    ! nvvidconv \
    ! waylandsink fullscreen=true sync=false
```

## 疑難排解

### 服務無法啟動

#### 問題: 服務狀態顯示 "failed"
```bash
sudo journalctl -u camera-kiosk -n 100
```

常見原因:
1. **Weston 未啟動**: 檢查 `systemctl status weston`
2. **nvargus-daemon 未執行**: 檢查 `systemctl status nvargus-daemon`
3. **相機未連接**: 檢查 `i2cdetect -y 7` 是否有 0x10
4. **Wayland socket 不存在**: 檢查 `/run/user/0/wayland-0`

#### 問題: 畫面黑屏
```bash
# 檢查相機裝置
ls -l /dev/video*

# 測試相機
gst-launch-1.0 nvarguscamerasrc num-buffers=100 ! fakesink

# 檢查 Argus 服務
systemctl status nvargus-daemon
journalctl -u nvargus-daemon
```

#### 問題: 服務一直重啟
```bash
# 查看重啟原因
sudo journalctl -u camera-kiosk | grep -i "restart\|fail\|error"

# 暫時停用自動重啟來除錯
sudo systemctl stop camera-kiosk
sudo systemctl edit camera-kiosk
# 加入:
# [Service]
# Restart=no

# 手動執行腳本來查看錯誤
sudo XDG_RUNTIME_DIR=/run/user/0 WAYLAND_DISPLAY=wayland-0 /usr/bin/camera-kiosk.sh
```

### 顯示問題

#### 問題: DisplayPort 無輸出
```bash
# 檢查顯示連接
modetest -M tegra-udrm -c

# 檢查 Weston 狀態
weston-info

# 檢查 DRM 模組
lsmod | grep nvidia
dmesg | grep -i drm
```

#### 問題: 畫面延遲或卡頓
- 降低解析度或幀率
- 停用 vsync: 使用 `sync=false`
- 檢查系統負載: `top`, `tegrastats`

### 權限問題

#### 問題: 無法存取 Wayland socket
```bash
# 檢查權限
ls -la /run/user/0/

# 確認環境變數
echo $XDG_RUNTIME_DIR
echo $WAYLAND_DISPLAY

# 服務檔案應該設定:
# Environment="XDG_RUNTIME_DIR=/run/user/0"
# Environment="WAYLAND_DISPLAY=wayland-0"
```

## 開發模式

### 臨時停用 Kiosk 模式

如果需要進行系統維護或開發:

```bash
# 停用並停止服務
sudo systemctl disable camera-kiosk
sudo systemctl stop camera-kiosk

# 此時可以正常使用 Weston 桌面環境
```

完成後重新啟用:

```bash
sudo systemctl enable camera-kiosk
sudo systemctl start camera-kiosk
```

### 測試管線而不啟動服務

```bash
# 設定環境變數
export XDG_RUNTIME_DIR=/run/user/0
export WAYLAND_DISPLAY=wayland-0

# 直接執行 GStreamer 管線
gst-launch-1.0 \
    nvarguscamerasrc \
    ! "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1" \
    ! nvvidconv \
    ! waylandsink fullscreen=true sync=false
```

## 效能最佳化

### 減少啟動時間

修改服務檔案中的延遲時間:

```ini
# 預設
ExecStartPre=/bin/sleep 5

# 快速啟動(需要確保相依服務已就緒)
ExecStartPre=/bin/sleep 2
```

### 降低 CPU 使用率

```bash
# 使用硬體編碼而非軟體編碼
# 調整 nvvidconv 參數
gst-launch-1.0 \
    nvarguscamerasrc \
    ! "video/x-raw(memory:NVMM),width=1280,height=720,framerate=30/1" \
    ! nvvidconv interpolation-method=1 \
    ! waylandsink fullscreen=true sync=false
```

### 記憶體最佳化

```bash
# 限制緩衝區數量
gst-launch-1.0 \
    nvarguscamerasrc bufapi-version=true \
    ! "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1" \
    ! nvvidconv \
    ! "video/x-raw(memory:NVMM)" \
    ! queue max-size-buffers=2 \
    ! waylandsink fullscreen=true sync=false
```

## 整合到 Yocto Build

### BitBake Recipe

`meta-my-project/recipes-apps/camera-kiosk/camera-kiosk.bb`:

```bitbake
SUMMARY = "Camera kiosk mode service for automatic fullscreen camera display"
DESCRIPTION = "Systemd service that automatically starts camera display in fullscreen mode"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://camera-kiosk.service \
    file://camera-kiosk.sh \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "camera-kiosk.service"
SYSTEMD_AUTO_ENABLE = "enable"

RDEPENDS:${PN} = "gstreamer1.0-plugins-tegra weston bash"

do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/camera-kiosk.service ${D}${systemd_system_unitdir}
    
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/camera-kiosk.sh ${D}${bindir}
}

FILES:${PN} = "${systemd_system_unitdir}/camera-kiosk.service ${bindir}/camera-kiosk.sh"
```

### 加入 Image

在 `project.yml` 或 `local.conf`:

```yaml
IMAGE_INSTALL:append = " camera-kiosk "
```

## 參考資料

- [IMX219 Camera Documentation](./IMX219-Camera-Setup.md)
- [DisplayPort Configuration Guide](./IMX219-DisplayPort-Usage-Guide.md)
- [GStreamer NVIDIA Plugins](https://docs.nvidia.com/jetson/archives/r36.4/DeveloperGuide/SD/Multimedia/AcceleratedGstreamer.html)
- [Weston Configuration](https://wayland.pages.freedesktop.org/weston/)
- [systemd Service Management](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

## 常見問題

**Q: 可以同時錄影和顯示嗎?**  
A: 可以,使用 `tee` 元件將管線分為顯示和錄影兩路,參考「新增錄影功能」章節。

**Q: 如何調整顯示品質?**  
A: 修改 `nvarguscamerasrc` 的解析度和幀率參數,或調整 `nvvidconv` 的 interpolation-method。

**Q: 支援其他相機型號嗎?**  
A: 只要是 NVIDIA Argus 支援的相機(如 IMX219, IMX477, IMX577 等)都可以使用,但可能需要調整解析度設定。

**Q: 可以在 HDMI 上顯示嗎?**  
A: 可以,Weston 會自動偵測可用的顯示輸出。如果同時連接 DisplayPort 和 HDMI,可以使用 `weston.ini` 設定優先順序。

**Q: 啟動時間可以更快嗎?**  
A: 可以調整 `ExecStartPre` 的延遲時間,但需要確保相依服務已經就緒。也可以最佳化 Weston 的啟動時間。

**Q: 如何新增多相機顯示(畫面分割)?**  
A: 需要使用 `videomixer` 或 `compositor` 元件來合成多個相機畫面,這需要更複雜的 GStreamer 管線設計。

