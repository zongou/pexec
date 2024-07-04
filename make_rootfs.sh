#!/bin/sh
set -eu

# Resource from void-linux
# https://voidlinux.org/download/#arm

# rootfs/
# ├── aarch64-linux-gnu
# │   ├── ld-linux-aarch64.so.1
# │   ├── libc.so.6
# │   ├── libdl.so.2
# │   ├── libgcc_s.so.1
# │   ├── libm.so.6
# │   ├── libpthread.so.0
# │   ├── libstdc++.so.6
# │   └── libutil.so.1
# ├── aarch64-linux-musl
# │   ├── ld-musl-aarch64.so.1
# │   ├── libgcc_s.so.1
# │   └── libstdc++.so.6
# └── etc
#     ├── hosts
#     ├── passwd
#     └── resolv.conf

script_dir="$(dirname "$(realpath "$0")")"
rootfs_dir="${script_dir}/rootfs"
checksum_b64=$(curl -LkSs https://repo-default.voidlinux.org/live/current/sha256sum.txt | base64)

musl_dir="${rootfs_dir}"/aarch64-linux-musl
mkdir -p "${musl_dir}"
f=$(echo "$checksum_b64" | base64 -d | grep -E '(void-aarch64-(musl-)?ROOTFS-[0-9]+.tar.xz)' | grep -E 'void-aarch64-musl-ROOTFS-[0-9]+.tar.xz' -o)
# curl -Lk https://repo-default.voidlinux.org/live/current/${f} | xz -d | tar -C "${musl_dir}" -xv --strip-components=3 \
curl -Lk https://mirrors.tuna.tsinghua.edu.cn/voidlinux/live/current/${f} | xz -d | tar -C "${musl_dir}" -xv --strip-components=3 \
	./usr/lib/libgcc_s.so.1 \
	./usr/lib/libc.so \
	./usr/lib/libstdc++.so.6.0.32
mv "${musl_dir}"/libstdc++.so.6.0.32 "${musl_dir}"/libstdc++.so.6
mv "${musl_dir}"/libc.so "${musl_dir}"/ld-musl-aarch64.so.1
## Shell reports error with softlink
# ln -snf libc.so ${musl_dir}/ld-musl-aarch64.so.1

glibc_dir="${rootfs_dir}"/aarch64-linux-gnu
mkdir -p "${glibc_dir}"
f=$(echo "$checksum_b64" | base64 -d | grep -E '(void-aarch64-(musl-)?ROOTFS-[0-9]+.tar.xz)' | grep -E 'void-aarch64-ROOTFS-[0-9]+.tar.xz' -o)
# curl -Lk https://repo-default.voidlinux.org/live/current/${f} | xz -d | tar -C "${glibc_dir}" -xv --strip-components=3 \
curl -Lk https://mirrors.tuna.tsinghua.edu.cn/voidlinux/live/current/${f} | xz -d | tar -C "${glibc_dir}" -xv --strip-components=3 \
	./usr/lib/libdl.so.2 \
	./usr/lib/libpthread.so.0 \
	./usr/lib/libgcc_s.so.1 \
	./usr/lib/libm.so.6 \
	./usr/lib/ld-linux-aarch64.so.1 \
	./usr/lib/libstdc++.so.6.0.32 \
	./usr/lib/libc.so.6 \
	./usr/lib/libutil.so.1
mv "${glibc_dir}"/libstdc++.so.6.0.32 "${glibc_dir}"/libstdc++.so.6

mkdir -p "${rootfs_dir}"/etc/
cat <<EOF >"${rootfs_dir}"/etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

cat <<EOF >"${rootfs_dir}"/etc/hosts
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

cat <<EOF >"${rootfs_dir}"/etc/passwd
root:x:0:0:root:/root:/bin/sh
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
lp:x:4:7:lp:/var/spool/lpd:/sbin/nologin
sync:x:5:0:sync:/sbin:/bin/sync
shutdown:x:6:0:shutdown:/sbin:/sbin/shutdown
halt:x:7:0:halt:/sbin:/sbin/halt
mail:x:8:12:mail:/var/mail:/sbin/nologin
news:x:9:13:news:/usr/lib/news:/sbin/nologin
uucp:x:10:14:uucp:/var/spool/uucppublic:/sbin/nologin
cron:x:16:16:cron:/var/spool/cron:/sbin/nologin
ftp:x:21:21::/var/lib/ftp:/sbin/nologin
sshd:x:22:22:sshd:/dev/null:/sbin/nologin
games:x:35:35:games:/usr/games:/sbin/nologin
ntp:x:123:123:NTP:/var/empty:/sbin/nologin
guest:x:405:100:guest:/dev/null:/sbin/nologin
nobody:x:65534:65534:nobody:/:/sbin/nologin
user:x:1000:1000:Linux User,,,:/home/user:/bin/bash
EOF

## Optional
if command -v llvm-strip >/dev/null; then
	find "${glibc_dir}" "${musl_dir}" -type f -exec llvm-strip --strip-all {} \;
fi
