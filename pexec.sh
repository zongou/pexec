#!/bin/sh
set -eu

script_dir="$(dirname "$(realpath "$0")")"
rootfs_dir="${script_dir}"/rootfs

unset LD_PRELOAD
export PROOT_TMP_DIR="${TMPDIR}"

if [ "${1+$1}" = "--glibc" ]; then
	shift
	export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu
else
	export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-musl
fi

exec proot \
	--change-id=1000:1000 \
	--kill-on-exit \
	--bind="${rootfs_dir}"/etc/resolv.conf:/etc/resolv.conf \
	--bind="${rootfs_dir}"/etc/hosts:/etc/hosts \
	--bind="${rootfs_dir}"/etc/passwd:/etc/passwd \
	--bind="${rootfs_dir}"/aarch64-linux-musl:/usr/lib/aarch64-linux-musl \
	--bind="${rootfs_dir}"/aarch64-linux-musl/ld-musl-aarch64.so.1:/lib/ld-musl-aarch64.so.1 \
	--bind="${rootfs_dir}"/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu \
	--bind="${rootfs_dir}"/aarch64-linux-gnu/ld-linux-aarch64.so.1:/lib/ld-linux-aarch64.so.1 \
	--bind=/system/bin/env:/usr/bin/env \
	--bind=/system/bin/sh:/bin/sh \
	"$@"
