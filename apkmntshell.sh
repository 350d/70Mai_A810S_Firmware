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