#!/bin/sh
# SOAL 17 - TXT record untuk seluruh client
# Jalankan di: PRAB (DNS master)
# dig alpha.k-03.com TXT  ->  "alpha"   (dst. beta, gamma, delta, epsilon)

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

DOMAIN="k-03.com"
ZONE="/var/bind/db.$DOMAIN"
CLIENTS="alpha beta gamma delta epsilon"

[ -f "$ZONE" ] || { echo "Zone $ZONE tidak ditemukan (jalankan di PRAB)"; exit 1; }

echo "[1/4] Tambah TXT record..."
ADDED=0
for h in $CLIENTS; do
    if ! grep -qE "^$h[[:space:]]+IN[[:space:]]+TXT" "$ZONE"; then
        [ "$ADDED" = "0" ] && echo "" >> "$ZONE"
        printf '%s\tIN\tTXT\t"%s"\n' "$h" "$h" >> "$ZONE"
        ADDED=1
    fi
done

echo "[2/4] Naikkan serial SOA..."
if [ "$ADDED" = "1" ]; then
    CUR=$(awk '/SOA/{f=1;next} f&&/^[[:space:]]*[0-9]+/{print $1;exit}' "$ZONE")
    NEW=$((CUR + 1))
    awk -v n="$NEW" '/SOA/{f=1;print;next} f&&!d&&/^[[:space:]]*[0-9]+/{sub(/[0-9]+/,n);d=1} {print}' \
        "$ZONE" > "$ZONE.new" && mv "$ZONE.new" "$ZONE"
    echo "Serial: $CUR -> $NEW"
else
    echo "TXT sudah ada semua, serial tidak diubah"
fi

echo "[3/4] Validasi & reload BIND..."
named-checkzone "$DOMAIN" "$ZONE" || exit 1
killall named 2>/dev/null
sleep 1
named -c /etc/bind/named.conf
sleep 4   

echo "[4/4] Verifikasi"
echo "--- PRAB (10.65.2.3)"
for h in $CLIENTS; do
    printf '%s.%s -> ' "$h" "$DOMAIN"; dig @10.65.2.3 "$h.$DOMAIN" TXT +short
done
echo "--- TEDD (10.65.2.2)"
for h in $CLIENTS; do
    printf '%s.%s -> ' "$h" "$DOMAIN"; dig @10.65.2.2 "$h.$DOMAIN" TXT +short
done
echo "--- Serial"
echo "PRAB: $(dig @10.65.2.3 $DOMAIN SOA +short | awk '{print $3}')"
echo "TEDD: $(dig @10.65.2.2 $DOMAIN SOA +short | awk '{print $3}')"
echo
echo "Dari client:  dig alpha.$DOMAIN TXT +short   -> \"alpha\""
