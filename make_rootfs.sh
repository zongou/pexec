#!/bin/sh
set -eu

# rootfs/
# ├── etc
# │   ├── hosts
# │   ├── passwd
# │   └── resolv.conf
# ├── lib
# │   ├── ld-musl-aarch64.so.1
# │   └── libc.musl-aarch64.so.1 -> ld-musl-aarch64.so.1
# └── usr
#     └── lib
#         ├── libgcc_s.so.1
#         ├── libstdc++.so.6 -> libstdc++.so.6.0.33
#         └── libstdc++.so.6.0.33

script_dir="$(dirname "$(realpath "$0")")"
rootfs_dir="${script_dir}/rootfs"
downloads="${script_dir}/downloads"
mkdir -p "${downloads}"
mkdir -p "${rootfs_dir}"

apk fetch --output "${downloads}" --recursive libstdc++
find "${downloads}" -type f -name "*.apk" -exec tar -C "${rootfs_dir}" -xvf {} \;
find "${rootfs_dir}" -maxdepth 1 -mindepth 1 -name ".*" -exec rm {} \;

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
