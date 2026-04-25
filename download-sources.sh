#!/bin/bash
set -e
DL=~/corosync-qnetd-openwrt/sdk-state/dl
mkdir -p $DL

wget -c "https://github.com/corosync/corosync-qdevice/archive/refs/tags/v3.0.4/corosync-qdevice-3.0.4.tar.gz" -O $DL/corosync-qdevice-3.0.4.tar.gz

wget -c "https://archive.mozilla.org/pub/nspr/releases/v4.35/src/nspr-4.35.tar.gz" -O $DL/nspr-4.35.tar.gz

wget -c "https://github.com/ClusterLabs/libqb/releases/download/v2.0.8/libqb-2.0.8.tar.gz" -O $DL/libqb-2.0.8.tar.gz

wget -c "https://archive.mozilla.org/pub/security/nss/releases/NSS_3_98_RTM/src/nss-3.98.tar.gz" -O $DL/nss-3.98.tar.gz

wget -c "https://github.com/kronosnet/kronosnet/archive/refs/tags/v1.28.tar.gz" -O $DL/v1.28.tar.gz

echo "全部下完了："
ls -lh $DL/
