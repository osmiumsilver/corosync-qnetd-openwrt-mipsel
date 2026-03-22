#!/bin/sh
#
# corosync-qnetd-setup [ip1] [ip2] ...
#
# Sets up the NSS certificate database, configures firewall rules for the
# given Proxmox node IPs, enables and starts corosync-qnetd.
#
# If no IPs are given, the firewall step is skipped and must be done manually.

NSSDB=/etc/corosync/qnetd/nssdb

# Generate NSS integrity check files if missing (required by PKCS#11 self-tests)
if [ ! -f /usr/lib/libfreeblpriv3.chk ] || [ ! -f /usr/lib/libsoftokn3.chk ]; then
    shlibsign -v -i /usr/lib/libfreeblpriv3.so
    shlibsign -v -i /usr/lib/libsoftokn3.so
fi

if [ ! -f "$NSSDB/cert9.db" ]; then
    # Clean any partial state from a previous failed attempt
    rm -f "$NSSDB"/*.db "$NSSDB"/*.dbm "$NSSDB"/*.sqldb "$NSSDB"/*.txt 2>/dev/null
    mkdir -p "$NSSDB"

    # Generate NSS database using the local certutil (same NSS version as qnetd).
    # Using a noise file avoids the need for a TTY during key generation.
    dd if=/dev/urandom bs=2048 count=1 of=/tmp/nss-noise.bin 2>/dev/null
    certutil -N -d sql:$NSSDB --empty-password
    certutil -S -n "QNet CA" -s "CN=QNet CA" -x -t "CT,," -m 1 -v 1200 \
        -d sql:$NSSDB -z /tmp/nss-noise.bin
    certutil -S -n "QNetd Cert" -s "CN=QNetd Server" \
        -c "QNet CA" -t "u,u,u" -m 2 -v 1200 \
        -d sql:$NSSDB -z /tmp/nss-noise.bin
    rm -f /tmp/nss-noise.bin

    chmod 700 "$NSSDB"
fi

# Firewall rule — single rule with all Proxmox node IPs as space-separated src_ip
if [ $# -gt 0 ]; then
    # Remove existing qnetd rule if present
    for name in $(uci show firewall | grep "name='Allow-QNetd-Proxmox'" | cut -d. -f2 | cut -d= -f1); do
        uci -q delete firewall.$name
    done

    src_ips="$*"
    uci add firewall rule
    uci set firewall.@rule[-1].name='Allow-QNetd-Proxmox'
    uci set firewall.@rule[-1].src='lan'
    uci set firewall.@rule[-1].src_ip="${src_ips}"
    uci set firewall.@rule[-1].dest_port='5403'
    uci set firewall.@rule[-1].proto='tcp'
    uci set firewall.@rule[-1].target='ACCEPT'
    echo "  firewall: allow TCP 5403 from ${src_ips}"

    uci commit firewall
    /etc/init.d/firewall restart
else
    echo "  No IPs given — skipping firewall setup."
    echo "  Run manually: corosync-qnetd-setup <node1-ip> [node2-ip] ..."
fi

# Ensure sftp-server is at the path dropbear expects (required for pvecm qdevice setup)
if [ ! -e /usr/libexec/sftp-server ] && [ -f /usr/lib/sftp-server ]; then
    mkdir -p /usr/libexec
    ln -sf /usr/lib/sftp-server /usr/libexec/sftp-server
fi

/etc/init.d/corosync-qnetd enable
/etc/init.d/corosync-qnetd start

echo "QNetd ready for Proxmox at port 5403"
