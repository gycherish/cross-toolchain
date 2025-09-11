#!/bin/bash

ROOTFS="$1"
if [ ! -d "$ROOTFS" ]; then
    echo "Rootfs not found: $ROOTFS"
    exit 1
fi

echo "Mounting necessary filesystems..."
mkdir -p "$ROOTFS/usr/local"
mkdir -p "$ROOTFS"/{dev,proc,tmp,src}
mount -v --bind /dev "$ROOTFS/dev"
mount -vt proc proc "$ROOTFS/proc"
mount -v --bind /home/gitee/cross-toolchain/source "$ROOTFS/src"

echo "Entering chroot environment..."
chroot "$ROOTFS" /bin/env -i \
    TERM="$TERM" \
    PS1='[chroot \W]\$ ' \
    PATH=/usr/local/bin:/usr/bin:/usr/sbin \
    HOME=/root \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/lib64/pkgconfig \
    /bin/bash --login

echo "Unmounting..."
umount -v "$ROOTFS/dev"
umount -v "$ROOTFS/proc"
umount -v "$ROOTFS/src"