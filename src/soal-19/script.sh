#!/bin/sh

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

DOMAIN="k-03.com"
ZONE="/var/bind/db.$DOMAIN"
PRAB="10.65.2.3"
TEDD="10.65.2.2"
EXT="http.badssl.com"

[ -f "$ZONE" ] || { echo "Zone $ZONE tidak ada (jalankan di PRAB)"; exit 1; }

echo "[1/4] Tambah CNAME (titik di akhir WAJIB: $EXT.)..."
if grep -q "^outbound[[:space:]]" "$ZONE"; then
    sed -i -E "s/^outbound[[:space:]].*/outbound    IN    CNAME    $EXT./" "$ZONE"
else
    printf 'outbound\tIN\tCNAME\t%s.\n' "$EXT" >> "$ZONE"
fi

echo "[2/4] Naikkan serial & reload..."
CUR=$(awk '/SOA/{f=1;next} f&&/^[[:space:]]*[0-9]+/{print $1;exit}' "$ZONE")
NEW=$((CUR + 1))
awk -v n="$NEW" '/SOA/{f=1;print;next} f&&!d&&/^[[:space:]]*[0-9]+/{sub(/[0-9]+/,n);d=1} {print}' \
    "$ZONE" > "$ZONE.new" && mv "$ZONE.new" "$ZONE"
echo "   serial: $CUR -> $NEW"
named-checkzone "$DOMAIN" "$ZONE" || exit 1
PID=""
for d in /proc/[0-9]*; do
    [ "$(cat "$d/comm" 2>/dev/null)" = "named" ] && { PID=${d#/proc/}; break; }
done
if [ -n "$PID" ]; then kill -HUP "$PID"; else named -c /etc/bind/named.conf; fi
sleep 2
if [ "$(dig @127.0.0.1 +short $DOMAIN SOA | awk '{print $3}')" != "$NEW" ]; then
    echo "   !! reload (HUP) tidak memuat zone baru -> restart named"
    [ -n "$PID" ] && kill "$PID"
    sleep 1
    named -c /etc/bind/named.conf
fi
sleep 4

echo "[3/4] Verifikasi DNS (harus ada CNAME lalu A dari $EXT)"
for S in $PRAB $TEDD; do
    echo "--- @$S"
    dig @"$S" +noall +answer +time=3 +tries=1 outbound.$DOMAIN A
done

echo "[4/4] Verifikasi curl"
curl -s -m 20 http://outbound.$DOMAIN -o /tmp/out-outbound.html -w "curl outbound.$DOMAIN -> HTTP %{http_code}\n"
curl -s -m 20 http://$EXT -o /tmp/out-original.html -w "curl $EXT -> HTTP %{http_code}\n"
echo
if [ -s /tmp/out-outbound.html ] && cmp -s /tmp/out-outbound.html /tmp/out-original.html; then
    echo "HASIL: SAMA - isi outbound.$DOMAIN identik dengan $EXT"
else
    echo "HASIL: BEDA / kosong. Cek file:"
    echo "  /tmp/out-outbound.html  vs  /tmp/out-original.html"
    echo "Kemungkinan: (a) server badssl memilih halaman dari header Host, atau"
    echo "             (b) prab/client tidak punya akses internet. Cek: dig +short $EXT"
fi
echo
echo "--- Isi halaman outbound.$DOMAIN (potongan):"
head -c 600 /tmp/out-outbound.html
echo
echo
echo "Dari client: curl http://outbound.$DOMAIN"