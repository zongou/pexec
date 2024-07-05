#!/bin/sh
set -eu

# Resource from void-linux
# https://voidlinux.org/download/#arm

# rootfs/
# ├── aarch64-linux-gnu
# │   ├── ld-linux-aarch64.so.1
# │   ├── libc.so.6
# │   ├── libdl.so.2
# │   ├── libgcc_s.so.1
# │   ├── libm.so.6
# │   ├── libpthread.so.0
# │   └── libstdc++.so.6
# ├── aarch64-linux-musl
# │   ├── ld-musl-aarch64.so.1
# │   ├── libgcc_s.so.1
# │   └── libstdc++.so.6
# └── etc
#     ├── hosts
#     ├── passwd
#     └── resolv.conf

script_dir="$(dirname "$(realpath "$0")")"
rootfs_dir="${script_dir}"/rootfs

unset LD_PRELOAD
export PROOT_TMP_DIR="${TMPDIR}"

if test $# -gt 0; then
	if command -v file >/dev/null; then
		if file "$1" 2>/dev/null | grep -q ld-linux-aarch64.so.1; then
			export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu
		else
			export LD_LIBRARY_PATH=/usr/lib/aarch64-linux-musl
		fi
	else
		printf "command file not found.\n" >&2
	fi
fi

exec proot \
	--change-id=1000:1000 \
	--kill-on-exit \
	--bind="${rootfs_dir}"/etc/resolv.conf:/etc/resolv.conf \
	--bind="${rootfs_dir}"/etc/hosts:/etc/hosts \
	--bind="${rootfs_dir}"/etc/passwd:/etc/passwd \
	--bind="${rootfs_dir}"/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu \
	--bind="${rootfs_dir}"/aarch64-linux-gnu/ld-linux-aarch64.so.1:/lib/ld-linux-aarch64.so.1 \
	--bind="${rootfs_dir}"/aarch64-linux-musl:/usr/lib/aarch64-linux-musl \
	--bind="${rootfs_dir}"/aarch64-linux-musl/ld-musl-aarch64.so.1:/lib/ld-musl-aarch64.so.1 \
	--bind=/system/bin/env:/usr/bin/env \
	--bind=/system/bin/sh:/bin/sh \
	"$@"
