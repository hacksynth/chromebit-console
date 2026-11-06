# chromebit-console

把 ASUS Chromebit CS10（RK3288 / 2GB / Arch Linux ARM）打造成一台**复古游戏机**：
开机直接进游戏前端、ROM 放在 NAS 上自动挂载、蓝牙/USB 手柄操作。

内核与系统的安装见姊妹仓库 [chromebit-kernel](https://github.com/hacksynth/chromebit-kernel)。

## 组成

| 组件 | 作用 |
|---|---|
| Xorg（modesetting） | 提供 GL 渲染，RetroArch/ES 都跑在 X 上 |
| `kiosk.sh` | 强制 1920×1080@60 CEA 时序（否则 X 选 120Hz → 无信号），再启动前端 |
| RetroArch + libretro 核心 | 模拟器运行时 |
| EmulationStation | 封面墙式前端（CI 编译，见下方） |
| `nas-roms.mount` | 把 NAS 的 ROM 共享挂到 `/mnt/nas/roms` |

## 为什么不用 RetroArch 的 KMSDRM / cage

- `SDL_VIDEODRIVER=kmsdrm` 在这块板子上会在 `GBM_FORMAT_ARGB8888` 后 **abort**
- `cage`（wlroots）需要 seat，且退出后控制台回不来
- **Xorg 是最稳的路径**：RetroArch 的 GL 驱动在 X 下最成熟

## 编译 EmulationStation

GitHub Runner 是 x86，而目标是 armv7，所以用 **QEMU + armv7 容器** 编译：

```console
gh workflow run build-es.yml -R <owner>/chromebit-console
gh run download <run-id> -R <owner>/chromebit-console -D out
tar xzf out/emulationstation-armv7.tar.gz -C /usr/local/bin
chmod +x /usr/local/bin/emulationstation
```

## 部署

```console
# 1) 前端
install -m755 configs/kiosk.sh /usr/local/bin/kiosk.sh
install -m644 configs/retroarch-kiosk.service /etc/systemd/system/
systemctl daemon-reload && systemctl enable retroarch-kiosk

# 2) EmulationStation 配置（ROM 目录来自 NAS）
mkdir -p /root/.emulationstation
cp configs/es_systems.cfg /root/.emulationstation/
# 主题：把主题目录放到 ~/.emulationstation/themes/

# 3) NAS
install -m600 configs/nas-creds /etc/nas-creds        # 填账号密码
install -m644 configs/nas-roms.mount /etc/systemd/system/mnt-nas-roms.mount
systemctl daemon-reload && systemctl enable --now mnt-nas-roms.mount
```

## 手柄

- **USB 手柄**：即插即用（HID）
- **蓝牙手柄**：需要内核带 `CONFIG_UHID` + `CONFIG_BT_HIDP`（chromebit-kernel 仓库的默认配置已包含），
  然后用 `bluetoothctl` 配对：`power on` → `agent on` → `scan on` → `pair <MAC>` → `trust <MAC>` → `connect <MAC>`

## 已知限制

- ARMv7 + 2GB：PS1 可用（pcsx_rearmed），N64 勉强，PSP/NGC 不行
- 音频走 HDMI；若 `aplay -l` 显示 `no soundcards`，需要核对 DTB 的 HDMI 声卡节点
- HDMI 只支持 1080p60 及以下（TMDS 上限 340MHz）
