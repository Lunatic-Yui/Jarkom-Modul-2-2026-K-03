#!/bin/sh

DOMAIN="k-03.com"
N=250
C=10

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

echo "[1/3] Install ApacheBench..."
apk update
apk add apache2-utils || { echo "Gagal apk add (cek DNS/internet)"; exit 1; }

run_ab() {
    URL="$1"
    OUT="/tmp/ab-$(echo "$URL" | sed 's|http://||; s|[^A-Za-z0-9]|_|g').txt"
    echo
    echo "============================================================"
    echo " ab -n $N -c $C $URL"
    echo "============================================================"
    ab -n "$N" -c "$C" "$URL" > "$OUT" 2>&1
    grep -E "^Server Hostname|^Document Path|^Document Length|^Concurrency Level|^Time taken|^Complete requests|^Failed requests|^Non-2xx|^Requests per second|^Time per request|^Transfer rate" "$OUT"
    echo "(output lengkap: $OUT)"
}

echo "[2/3] Tes www.$DOMAIN (gerbang penny -> vault)"
run_ab "http://www.$DOMAIN/"

echo "[3/3] Tes static.$DOMAIN (gerbang abbey -> core)"
run_ab "http://static.$DOMAIN/"

echo
echo "Result: "
for f in /tmp/ab-http_www_*.txt /tmp/ab-http_static_*.txt; do
    [ -f "$f" ] || continue
    HOST=$(awk '/^Server Hostname/{print $3}' "$f")
    DONE=$(awk '/^Complete requests/{print $3}' "$f")
    FAIL=$(awk '/^Failed requests/{print $3}' "$f")
    N2=$(awk '/^Non-2xx/{print $3}' "$f"); N2=${N2:-0}
    RPS=$(awk '/^Requests per second/{print $4}' "$f")
    TPR=$(awk '/^Time per request/ && /mean\)$/ && !/across/{print $4}' "$f" | head -n1)
    echo "$HOST : complete=$DONE failed=$FAIL non2xx=$N2 rps=$RPS ms/req(mean)=$TPR"
done
echo