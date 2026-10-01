#!/bin/sh

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

DOMAIN="k-03.com"
ZONE="/var/bind/db.$DOMAIN"
HOST="abbey"
OLD_IP="10.65.4.2"
TTL=15
PRAB="10.65.2.3"
TEDD="10.65.2.2"
CDIR="/tmp/demo-cache"
CPORT=5353
NEW_IP=$(awk 'BEGIN{srand(); printf "203.0.113.%d", 1+int(rand()*253)}')   # IP fiktif valid

[ -f "$ZONE" ] || { echo "Zone $ZONE tidak ada (jalankan di PRAB)"; exit 1; }
grep -q "^$HOST[[:space:]]" "$ZONE" || { echo "Record $HOST tidak ada di zone"; exit 1; }

set_abbey() {
    sed -i -E "s/^$HOST[[:space:]].*/$HOST    $TTL    IN    A    $1/" "$ZONE"
}
bump_serial() {
    CUR=$(awk '/SOA/{f=1;next} f&&/^[[:space:]]*[0-9]+/{print $1;exit}' "$ZONE")
    NEW=$((CUR + 1))
    awk -v n="$NEW" '/SOA/{f=1;print;next} f&&!d&&/^[[:space:]]*[0-9]+/{sub(/[0-9]+/,n);d=1} {print}' \
        "$ZONE" > "$ZONE.new" && mv "$ZONE.new" "$ZONE"
    echo "   serial SOA: $CUR -> $NEW"
}
# PID named utama (bukan resolver demo), dibaca dari /proc supaya tidak bergantung pada 'ps'
main_pid() {
    DEMO=$(cat "$CDIR/named.pid" 2>/dev/null)
    for d in /proc/[0-9]*; do
        [ "$(cat "$d/comm" 2>/dev/null)" = "named" ] || continue
        p=${d#/proc/}
        [ "$p" != "$DEMO" ] && { echo "$p"; return; }
    done
}
file_serial() { awk '/SOA/{f=1;next} f&&/^[[:space:]]*[0-9]+/{print $1;exit}' "$ZONE"; }
reload_main() {
    named-checkzone "$DOMAIN" "$ZONE" >/dev/null || { echo "Zone error!"; exit 1; }
    PID=$(main_pid)
    if [ -n "$PID" ]; then kill -HUP "$PID"; else named -c /etc/bind/named.conf; fi
    i=0
    while [ $i -lt 3 ]; do
        sleep 1
        [ "$(serial_of 127.0.0.1)" = "$(file_serial)" ] && return 0
        i=$((i+1))
    done
    echo "   !! reload (HUP) tidak memuat zone baru -> restart named utama"
    [ -n "$PID" ] && kill "$PID"
    sleep 1
    named -c /etc/bind/named.conf
    sleep 2
}
serial_of() { dig @"$1" +short +time=2 +tries=1 "$DOMAIN" SOA | awk '{print $3}'; }
wait_sync() {
    i=0
    while [ $i -lt 10 ]; do
        [ "$(serial_of $PRAB)" = "$(serial_of $TEDD)" ] && [ -n "$(serial_of $TEDD)" ] && return 0
        i=$((i+1)); sleep 1
    done
    return 1
}
cache_q() { dig @127.0.0.1 -p $CPORT +noall +answer +time=2 +tries=1 "$HOST.$DOMAIN" A; }
auth_q()  { printf '   %-14s' "$1"; dig @"$2" +short +time=2 +tries=1 "$HOST.$DOMAIN" A; }
stop_cache() { [ -f "$CDIR/named.pid" ] && kill "$(cat $CDIR/named.pid)" 2>/dev/null; sleep 1; }

echo "[0/5] Persiapan: abbey = $OLD_IP dengan TTL $TTL, sinkron ke tedd..."
set_abbey "$OLD_IP"; bump_serial; reload_main
wait_sync && echo "   tedd tersinkron (serial $(serial_of $TEDD))" || echo "   !! tedd belum sinkron"

echo "[1/5] Nyalakan resolver cache demo..."
stop_cache
mkdir -p "$CDIR"
cat > "$CDIR/named.conf" <<EOF
options {
    directory "$CDIR";
    pid-file "$CDIR/named.pid";
    session-keyfile "$CDIR/session.key";
    listen-on port $CPORT { 127.0.0.1; };
    listen-on-v6 { none; };
    allow-query { 127.0.0.1; };
    allow-recursion { 127.0.0.1; };
    recursion yes;
    forward only;
    forwarders { $PRAB; };
    dnssec-validation no;
};
controls { };
EOF
named -c "$CDIR/named.conf" || { echo "Gagal start resolver demo"; exit 1; }
i=0
until dig @127.0.0.1 -p $CPORT +short +time=2 +tries=1 prab.$DOMAIN A | grep -q .; do
    i=$((i+1)); [ $i -ge 8 ] && { echo "Resolver demo tidak merespons"; stop_cache; exit 1; }
    sleep 1
done

echo
echo "Sebelum perubahan"
cache_q
T0=$(date +%s)

echo
echo "[2/5] Mengubah $HOST.$DOMAIN -> $NEW_IP (secepat mungkin)..."
set_abbey "$NEW_IP"; bump_serial; reload_main

echo
echo "Perubahan baru terjadi"
cache_q
echo "   (selang sejak fase 1: $(( $(date +%s) - T0 )) detik)"
echo "   --- authoritative sudah memberi IP baru:"
auth_q "prab" "$PRAB"
i=0; while [ $i -lt 6 ] && [ "$(serial_of $PRAB)" != "$(serial_of $TEDD)" ]; do i=$((i+1)); sleep 1; done
auth_q "tedd" "$TEDD"
echo "   serial prab: $(serial_of $PRAB) | serial tedd: $(serial_of $TEDD)"

W=$((T0 + TTL + 2 - $(date +%s)))
echo
echo "[3/5] Menunggu TTL habis (${W}s)..."
[ "$W" -gt 0 ] && sleep "$W"

echo
echo "TTL habis"
cache_q
echo "   (selang sejak fase 1: $(( $(date +%s) - T0 )) detik)"

echo
echo "[4/5] Matikan resolver demo..."
stop_cache
echo "[5/5] Selesai. IP lama: $OLD_IP | IP fiktif sekarang: $NEW_IP"