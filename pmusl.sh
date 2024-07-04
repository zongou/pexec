#!/bin/sh
set -eu

script_dir="$(dirname "$(realpath "$0")")"
rootfs_dir="${script_dir}/rootfs"

unset LD_PRELOAD
export PROOT_TMP_DIR="${TMPDIR}"

exec proot \
	--change-id=1000:1000 \
	--kill-on-exit \
	--bind="${rootfs_dir}/etc/resolv.conf:/etc/resolv.conf" \
	--bind="${rootfs_dir}/etc/hosts:/etc/hosts" \
	--bind="${rootfs_dir}/etc/passwd:/etc/passwd" \
	--bind="${rootfs_dir}/lib:/lib" \
	--bind="${rootfs_dir}/usr:/usr" \
	--bind=/system/bin/env:/usr/bin/env \
	--bind=/system/bin/sh:/bin/sh \
	"$@"
