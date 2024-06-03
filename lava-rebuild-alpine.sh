#!/bin/sh

#
# lava-rebuild-alpine.sh
#
# Self-hosted image regeneration! Needs to be run as root.
#

set -ex

# Install prerequisites
apk add --no-interactive --no-progress e2fsprogs zstd

# Rebuild the rootfs
./alpine-make-rootfs \
	alpine-base-latest.tar \
	--script-chroot bootable/tweak-image \
	--packages "$EXTRA_PACKAGES"
zstd -19 --no-progress --force alpine-base-latest.tar

# Package the rootfs as an ext4 filesystem
mkfs.ext4 -L rootfs alpine-base-latest.ext4 1G
mkdir sysimage
mount -o loop alpine-base-latest.ext4 sysimage
tar -C sysimage/ -xf alpine-base-latest.tar

# Package the rootfs as an initramfs
(cd sysimage/; find . -print | cpio -o -H newc) | zstd -19 --no-progress > alpine-base-latest.cpio.zst

# Finalize and compress the ext4 image
umount sysimage
zstd -19 --no-progress --rm --force alpine-base-latest.ext4
