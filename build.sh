#!/bin/bash
set -e

SDK_DIR=/opt/sdk
OUTPUT_DIR=/build/output

mkdir -p ${OUTPUT_DIR}

cp -r /build/package/* ${SDK_DIR}/package/

cd ${SDK_DIR}

cat <<EOF > .config
CONFIG_TARGET_armsr=y
CONFIG_TARGET_armsr_armv8=y

CONFIG_PACKAGE_libqb=m
CONFIG_PACKAGE_libknet=m
CONFIG_PACKAGE_libnspr=m
CONFIG_PACKAGE_libnss=m

CONFIG_PACKAGE_corosync-qnetd=m
CONFIG_PACKAGE_corosync-nss-tools=m
EOF

make defconfig

make package/corosync/libqb/compile V=s -j$(nproc)
make package/corosync/nspr/compile V=s -j$(nproc)
make package/corosync/nss/compile V=s -j$(nproc)

make package/corosync/libknet/compile V=s -j$(nproc)
make package/corosync/corosync-qnetd/compile V=s -j$(nproc)

rm -f ${OUTPUT_DIR}/*.ipk
find bin/packages -name "*.ipk" -exec cp {} ${OUTPUT_DIR}/ \;

# Repack ipks: change Architecture field to match the GL.iNet router's arch string.
# The binaries are identical — this is purely a metadata fix so opkg accepts them.
ROUTER_ARCH="aarch64_cortex-a53_neon-vfpv4"
for ipk in ${OUTPUT_DIR}/*.ipk; do
    tmpdir=$(mktemp -d)
    (
        cd "$tmpdir"
        tar xzf "$ipk"
        mkdir ctrl
        tar xzf control.tar.gz -C ctrl
        sed -i "s/^Architecture: .*/Architecture: ${ROUTER_ARCH}/" ctrl/control
        (cd ctrl && tar czf ../control.tar.gz .)
        rm "$ipk"
        tar czf "$ipk" debian-binary control.tar.gz data.tar.gz
    )
    rm -rf "$tmpdir"
done

echo "Build complete:"
ls -lh ${OUTPUT_DIR}
