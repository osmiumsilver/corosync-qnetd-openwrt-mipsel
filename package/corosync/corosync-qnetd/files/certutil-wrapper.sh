#!/bin/sh
#
# corosync-qnetd-certutil
# Server-side NSS certificate management for corosync-qnetd.
# Called remotely by Proxmox pvecm qdevice setup.
#
# -i                         Export CA certificate (initialize)
# -s -n cluster -c cert_req  Sign cluster cert request, output signed cert to stdout
#

NSSDB="/etc/corosync/qnetd/nssdb"
CA_NICKNAME="QNet CA"

do_init() {
    if [ ! -f "$NSSDB/cert9.db" ]; then
        mkdir -p "$NSSDB"
        dd if=/dev/urandom bs=2048 count=1 of=/tmp/nss-noise.bin 2>/dev/null
        certutil -N -d "sql:$NSSDB" --empty-password || exit 1
        certutil -S -n "$CA_NICKNAME" -s "CN=QNet CA" -x -t "CT,," \
            -m 1 -v 1200 -d "sql:$NSSDB" -z /tmp/nss-noise.bin || exit 1
        certutil -S -n "QNetd Cert" -s "CN=QNetd Server" \
            -c "$CA_NICKNAME" -t "u,u,u" -m 2 -v 1200 \
            -d "sql:$NSSDB" -z /tmp/nss-noise.bin || exit 1
        rm -f /tmp/nss-noise.bin
        chmod 700 "$NSSDB"
        shlibsign -v -i /usr/lib/libfreeblpriv3.so >/dev/null 2>&1 || true
        shlibsign -v -i /usr/lib/libsoftokn3.so >/dev/null 2>&1 || true
    fi
    certutil -L -d "sql:$NSSDB" -n "$CA_NICKNAME" -a \
        > "$NSSDB/qnetd-cacert.crt" || exit 1
}

do_sign() {
    local cluster_name="$1"
    local cert_request_file="$2"

    local tmpreq tmpcert tmpca_cert tmpca_key tmpca_p12
    tmpreq=$(mktemp /tmp/qnetd-req-XXXXXX)
    tmpcert=$(mktemp /tmp/qnetd-cert-XXXXXX)
    tmpca_cert=$(mktemp /tmp/qnetd-ca-cert-XXXXXX)
    tmpca_key=$(mktemp /tmp/qnetd-ca-key-XXXXXX)
    tmpca_p12=$(mktemp /tmp/qnetd-ca-p12-XXXXXX)

    if [ -n "$cert_request_file" ]; then
        cp "$cert_request_file" "$tmpreq"
    else
        cat > "$tmpreq"
    fi

    # Export CA cert from NSS
    certutil -L -d "sql:$NSSDB" -n "$CA_NICKNAME" -a > "$tmpca_cert" || {
        rm -f "$tmpreq" "$tmpcert" "$tmpca_cert" "$tmpca_key" "$tmpca_p12"
        exit 1
    }

    # Export CA key from NSS via PKCS#12
    pk12util -o "$tmpca_p12" -d "sql:$NSSDB" -n "$CA_NICKNAME" -W "" 2>/dev/null || {
        rm -f "$tmpreq" "$tmpcert" "$tmpca_cert" "$tmpca_key" "$tmpca_p12"
        exit 1
    }

    # Extract CA private key (OpenSSL 3.x needs -legacy for NSS-generated PKCS#12)
    openssl pkcs12 -legacy -in "$tmpca_p12" -nocerts -nodes \
        -out "$tmpca_key" -passin pass: 2>/dev/null || \
    openssl pkcs12 -in "$tmpca_p12" -nocerts -nodes \
        -out "$tmpca_key" -passin pass: 2>/dev/null || {
        rm -f "$tmpreq" "$tmpcert" "$tmpca_cert" "$tmpca_key" "$tmpca_p12"
        exit 1
    }

    # Sign the cert request with OpenSSL (accepts DER input)
    openssl x509 -req \
        -in "$tmpreq" -inform DER \
        -CA "$tmpca_cert" -CAkey "$tmpca_key" \
        -CAcreateserial \
        -out "$tmpcert" \
        -days 730 \
        -sha256 2>/dev/null
    local ret=$?

    if [ $ret -eq 0 ]; then
        cat "$tmpcert"
        cp "$tmpcert" "$NSSDB/cluster-${cluster_name}.crt"
    fi
    rm -f "$tmpreq" "$tmpcert" "$tmpca_cert" "$tmpca_key" "$tmpca_p12"
    rm -f "${tmpca_cert}.srl" 2>/dev/null
    return $ret
}

INIT=0
SIGN=0
CLUSTER_NAME=""
CERT_REQUEST_FILE=""

while getopts "isn:d:c:t:CfFph" opt; do
    case "$opt" in
    i) INIT=1 ;;
    s) SIGN=1 ;;
    n) CLUSTER_NAME="$OPTARG" ;;
    c) CERT_REQUEST_FILE="$OPTARG" ;;
    *) ;;
    esac
done

if [ $INIT -eq 1 ]; then
    do_init
    exit $?
fi

if [ $SIGN -eq 1 ]; then
    [ -z "$CLUSTER_NAME" ] && { echo "cluster name required (-n)" >&2; exit 1; }
    do_sign "$CLUSTER_NAME" "$CERT_REQUEST_FILE"
    exit $?
fi

echo "Usage: $0 -i | -s -n cluster_name [-c cert_request_file]" >&2
exit 1
