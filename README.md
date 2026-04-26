# Corosync QNetd for OpenWrt (mipsel_24kc)

Cross-compiled `corosync-qnetd` package for OpenWrt, targeting mipsel_24kc/musl (ramips-mt7620).

Based on the original aarch64 build by [jrparks/corosync-qnetd-openwrt](https://github.com/jrparks/corosync-qnetd-openwrt). Adapted for mipsel 32-bit targets with a stripped-down NSS to keep compile times reasonable on more common hardware.

---

## What Changed from Upstream
 
**OpenWrt 25.12 migration**
- Package format changed from `.ipk` (opkg) to `.apk` (apk), build scripts updated accordingly
- Added runtime dependencies that OpenWrt 25.12 doesn't bundles by default but necessary: `coreutils-chown`, `coreutils-stat`, `coreutils-sha1sum`, `procps-ng`, `openssh-sftp-server`, `bash`
**Minimal NSS build (`nss-qnetd`)**
- Full NSS takes too long to compile; `nss-qnetd` builds only the libraries needed by corosync-qnetd (`libnss3.so`, `libssl3.so`, `libsmime3.so`, `libnssutil3.so`, `libsoftokn3.so`, `libfreebl3.so`)
- Disabled DBM (`NSS_DISABLE_DBM=1`) and LIBPKIX (`NSS_DISABLE_LIBPKIX=1`) to skip sqlite3 and PKIX dependencies
- `nss-qnetd` declares `PROVIDES:=libnss` so the packaging system resolves `libnss3.so` correctly, while the runtime `DEPENDS:=+libnss` in corosync-qnetd pulls the official `libnss` from the feed on the router
- Cross-compile flags adapted for mipsel 32-bit (`OS_ARCH=Linux`, `OS_TEST=mipsel`, `CPU_ARCH=mipsel`, no `USE_64`)
**Removed packages**
- `libknet`, `libqb`, `corosync-nss-tools` — not required for qnetd-only operation
- `corosync-qnetd-setup` script removed; firewall rules are left to the user in order to keep "package only"

---

## Packages

```
corosync-qnetd_3.0.4-r2.apk
libnss-qnetd_3.112-r1.apk       (build-time only, installation not required)
```

The router uses the official `libnss` from opkg/apk feeds at runtime. `libnss-qnetd` exists solely to provide headers and `.so` files during cross-compilation.

---

## Build

```bash
# Build the Docker image (first time only)
docker build -t openwrt-corosync .

# Run the build (state is cached in sdk-state/)
bash run-build.sh

# Follow the log
tail -f output/build.log
```

Output `.apk` files are written to `output/`.

---

## Install

```bash
# Copy package to router
scp -O output/corosync-qnetd*.apk root@<router>:/tmp/

# Install
ssh root@<router>
apk add --allow-untrusted /tmp/corosync-qnetd-3.0.4-r1.apk
```

All dependencies (`libnss`, `nspr`, `nss-utils`, `bash`, `coreutils-chown`, `coreutils-stat`, `coreutils-sha1sum`, `procps-ng`, `openssh-sftp-server`, `openssl-util`) are pulled automatically from the OpenWrt feed.

---

## Setup
 
```bash
# Initialize NSS certificate database
corosync-qnetd-certutil -i
 
# Start and enable the service
/etc/init.d/corosync-qnetd start
/etc/init.d/corosync-qnetd enable
```

---
 
## Proxmox Integration
 
On one Proxmox node:
 
```bash
pvecm qdevice setup <router-ip>
```
 
Use `--force` if re-running after a previous attempt:
 
```bash
pvecm qdevice setup <router-ip> --force
```
 
Once complete, `pvecm status` should show `Qdevice` with 1 vote, giving a 2-node cluster a proper tiebreaker.

---


## Usage
 
```bash
# Start / stop / status
/etc/init.d/corosync-qnetd start
/etc/init.d/corosync-qnetd stop
/etc/init.d/corosync-qnetd status
 
# Check connected clients
corosync-qnetd-tool -l
 
# Run in foreground (debugging)
corosync-qnetd -f
 
# Check if listening
netstat -tlnp | grep 5403
```

---


## Uninstallation

```bash
pvecm qdevice remove          # on Proxmox node first
apk del corosync-qnetd        # on router
```

---

## Notes

- **OpenWrt 25.12.2** ramips/mt7620 (mipsel_24kc, musl) tested, OpenWrt 24.10 and earlier are not supported. Build with your own SDK at your own risk.
- `corosync-qnetd` source: [corosync/corosync-qdevice](https://github.com/corosync/corosync-qdevice)
- `sdk-state/` is gitignored and holds cached build artifacts between runs
- Key generation on mipsel hardware is slow (~5-10 minutes) — be patient during `corosync-qnetd-certutil -i`
