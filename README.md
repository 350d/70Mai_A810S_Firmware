# 70Mai A810S Custom Firmware

Custom firmware project for the 70Mai A810S dashcam, focused on startup speed, stability, network control, and advanced power-user features.
Based on latest 1.5.40ww OTA firmware.

![70Mai A810S Custom Firmware Logo](logo.png)

## Intro Highlights

- Three extra voice packs are available (`Alice`, `Petr`, `Vladimir`), selected by system language.
- Main recording stream bitrate is increased by 25%.
- Bitrate for reduced album copies is lowered by 2x (from ~17 MB to ~8.5 MB per file).
- Video storage quota on SD card is increased to 98% (was 92%).
- Full Wi-Fi control is available via SD config: `STA` / `AP` / `OFF` / `NORMAL`.
- If Wi-Fi mode is not `NORMAL`, app/device do not override SD config settings.
- Custom Wi-Fi `SSID` and `PASS` can be defined; default password is now `multipass`.
- Auto-start support for `apkmntshell.sh` (legacy-style behavior from older models) is enabled.
- Web Admin is available at `http://<dashcam-ip>` for full control, gallery access, and log download (Beta).
- Password requirement for log file access is disabled.
- Signature validation for HTTP control requests is disabled.
- FTP is enabled (access to `/` or SD card, depending on setup).
- Telnet is enabled.

## How to Flash

1. Download and unzip the firmware `FW98529A.zip` file from this project release/build.
2. Copy the `FW98529A.bin` file to the root of the SD card.
3. Safely eject the SD card and insert it into the dashcam.
4. Power on the device.
5. Wait until the flashing process completes (do not power off during update).
6. After reboot, verify firmware behavior and key features.

## Project Goals

This firmware line is built for power users who need a more controllable and predictable device behavior than stock firmware provides.

Primary goals:
- reduce time to first recording after boot,
- improve reliability under long sessions,
- expose operational controls through Web Admin,
- optimize network-related features (preview streaming, STA use cases),
- provide safe and repeatable patching workflow.

## Major Firmware Updates

### 1) Faster recording startup

Startup path was optimized to reduce delay before first valid recording segment.  
Typical improvements come from:
- reducing startup service contention,
- prioritizing recorder initialization sequence,
- delaying non-critical background tasks until recording is active.

Expected result: camera begins writing usable footage earlier after power-on.

### 2) Stability and long-run reliability

Changes are aimed at minimizing soft-fail states during long recording sessions:
- safer startup script behavior,
- reduced race conditions between service init scripts,
- better handling of optional feature failures (non-critical modules should not block recording).

Expected result: fewer random service stalls and more deterministic operation.

### 3) Lower preview bitrate

Preview stream bitrate was reduced to improve:
- app responsiveness on weaker links,
- Wi-Fi preview smoothness in noisy environments,
- thermal/network load during long sessions.

At 480p preview resolution, visual quality remains effectively unchanged in normal use, while preview file size is reduced by around 2x.
This also increases free space available on the SD card for recording.

### 4) Web Admin improvements

Web Admin additions improve operational control without rebuilding firmware:
- quick status checks,
- easier config edits,
- no app required

Expected result: less manual shell work and shorter test iteration cycles.

### 5) New quotas and practical benefit

Storage/resource quota refinements are intended to:
- protect recording paths from being exhausted by logs/temp files,
- keep enough reserved space for critical recorder outputs,
- improve survivability in unattended long-term usage.

Expected result: fewer failures caused by filesystem pressure.

## Auto-start Script Example (logo deployment)

This is an example SD auto-start script (`apkmntshell.sh`) that copies a pre-converted custom logo into the target location at boot.

> Note: convert your source image to `logo_2820.yuv` format first (640x360, YUV420p raw).
> An online converter is available here: [logo_2820.yuv converter](https://parkplay.ee/70mai/a810s/logo/).

```sh
#!/bin/sh
# Auto-apply boot logo from SD card.
# Source priority: /mnt/sd/logo_2820.yuv, then /mnt/sd/logo.yuv

SRC1="/mnt/sd/logo_2820.yuv"
SRC2="/mnt/sd/logo.yuv"
DST_DIR="/mnt/app/BootLogo"
DST="${DST_DIR}/logo_2820.yuv"
BAK="${DST_DIR}/logo_2820_original.yuv"

echo "[logo] start $(date)"

# Pick source
if [ -f "${SRC1}" ]; then
    SRC="${SRC1}"
elif [ -f "${SRC2}" ]; then
    SRC="${SRC2}"
else
    echo "[logo] no source file on SD"
    exit 0
fi

# Backup original only once
if [ ! -f "${BAK}" ] && [ -f "${DST}" ]; then
    cp -f "${DST}" "${BAK}" || {
        echo "[logo] backup failed"
        exit 1
    }
    sync
    echo "[logo] backup created: ${BAK}"
fi

# Replace logo
cp -f "${SRC}" "${DST}" || {
    echo "[logo] copy failed: ${SRC} -> ${DST}"
    exit 1
}

#chmod 755 "${DST}" 2>/dev/null
#sync

echo "[logo] applied: ${SRC} -> ${DST}"
exit 0
```

## `config.txt` Example

Example startup config for SD-based script launcher:

```ini
# config.txt

wifi_mode=STA
wifi_sta_ssid=*****
wifi_sta_pass=******
wifi_ap_ssid=70Mai_A810S
wifi_ap_pass=multipass
ftpd=1/2
telnet=1
debug=0/1
```

Parameter notes:
- `wifi_ap_ssid`: custom AP SSID is supported, but it must keep the `70Mai_****` mask or the mobile app may fail to connect. Since network name rendering in the dashcam menu cannot be overridden, the menu still shows the default SSID.
- `telnet`: `root` login, no password.
- `ftpd`: `root` login, no password. `1` = SD card access, `2` = full filesystem access.
- `debug`: enables logs for mod custom scripts and `apkmntshell.sh`. Default is `0` (off). When enabled, it can block standard SD card formatting from the stock UI.

## STA Mode Use Case

STA mode is useful when the dashcam must join an existing Wi-Fi network instead of acting only as an AP.

Practical scenarios:
- remote access inside car/garage/home LAN,
- stable integration with a fixed router and static monitoring setup,
- easier automated log collection over LAN.

Typical flow:
1. Configure SSID/password for target network.
2. Boot camera and ensure STA association succeeds.
3. Access Web Admin or services from LAN IP.
4. Validate stream/preview latency and reconnect behavior after Wi-Fi loss.

## UVC Research Status (Work in Progress)

UVC (USB Video Class) support is currently an active research direction, but progress is still incomplete.

### What has been explored

- enumeration behavior under different USB modes,
- initial checks for UVC gadget/kernel prerequisites,
- interface compatibility testing with host software.

### Current blockers

- missing or incompatible components in the current firmware stack,
- unstable behavior in partial bring-up attempts,
- no production-ready end-to-end path yet.

### Current conclusion

UVC is **not ready** for release in this firmware branch.  
It remains an experimental area and needs additional reverse engineering, compatibility validation, and reliability tests before integration.

## Validation Recommendations

Before publishing a build:
- run startup/recording timing checks across multiple cold boots,
- verify preview stream behavior under weak Wi-Fi,
- test script-based customizations with rollback path,
- confirm no regression in normal recording workflow.

## Disclaimer

This project is community-driven and provided as-is.  
Always keep recovery options and stock firmware backups before flashing modified builds.
