#!/bin/sh

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

DOMAIN="k-03.com"
ZONE="/var/bind/db.$DOMAIN"
PRAB="10.65.2.3"
TEDD="10.65.2.2"
BASE=2026100101

# --- Tentukan serial: tidak boleh lebih kecil dari serial lama (prab/tedd),
#     kalau tidak tedd menolak menarik zone ---
OLD_FILE=0
[ -f "$ZONE" ] && OLD_FILE=$(awk '/SOA/{f=1;next} f&&/^[[:space:]]*[0-9]+/{print $1;exit}' "$ZONE")
OLD_TEDD=$(dig @"$TEDD" +short +time=2 +tries=1 "$DOMAIN" SOA 2>/dev/null | awk '{print $3}')
case "$OLD_FILE" in ''|*[!0-9]*) OLD_FILE=0 ;; esac
case "$OLD_TEDD" in ''|*[!0-9]*) OLD_TEDD=0 ;; esac
SERIAL=$BASE
[ "$OLD_FILE" -ge "$SERIAL" ] && SERIAL=$((OLD_FILE + 1))
[ "$OLD_TEDD" -ge "$SERIAL" ] && SERIAL=$((OLD_TEDD + 1))
echo "[1/4] Serial: file=$OLD_FILE tedd=$OLD_TEDD -> pakai $SERIAL"

# --- Backup zone lama ---
[ -f "$ZONE" ] && cp "$ZONE" "$ZONE.bak.$(date +%s)"

echo "[2/4] Tulis ulang zone..."
cat > "$ZONE" <<EOF
\$TTL 86400

@   IN  SOA prab.$DOMAIN. root.$DOMAIN. (
        $SERIAL
        3600
        1800
        604800
        86400
)

@       IN  NS      prab.$DOMAIN.
@       IN  NS      tedd.$DOMAIN.

@       IN  A       10.65.5.2

prab    IN  A       10.65.2.3
tedd    IN  A       10.65.2.2

rootkit IN  A       10.65.1.1

alpha   IN  A       10.65.6.2
beta    IN  A       10.65.6.3
gamma   IN  A       10.65.6.4

delta   IN  A       10.65.7.2
epsilon IN  A       10.65.7.3

abbey   IN  A       10.65.4.2
penny   IN  A       10.65.5.2

obladi  IN  A       10.65.3.5
desmond IN  A       10.65.3.4
oblada  IN  A       10.65.3.3
molly   IN  A       10.65.3.2

vault   IN  A       10.65.3.5
vault   IN  A       10.65.3.4

core    IN  A       10.65.3.3
core    IN  A       10.65.3.2

www     IN  CNAME   penny.$DOMAIN.
static  IN  CNAME   abbey.$DOMAIN.

alpha   IN  TXT     "alpha"
beta    IN  TXT     "beta"
gamma   IN  TXT     "gamma"
delta   IN  TXT     "delta"
epsilon IN  TXT     "epsilon"

outbound IN CNAME   http.badssl.com.
EOF

echo "[3/4] Validasi & restart named..."
named-checkzone "$DOMAIN" "$ZONE" || { echo "Zone error, batal"; exit 1; }
killall named 2>/dev/null
sleep 1
named -c /etc/bind/named.conf
sleep 5

echo "[4/4] Verifikasi"
echo "serial prab : $(dig @$PRAB +short $DOMAIN SOA | awk '{print $3}')"
echo "serial tedd : $(dig @$TEDD +short $DOMAIN SOA | awk '{print $3}')  (harus sama)"
echo "www         : $(dig @$PRAB +short www.$DOMAIN A | tr '\n' ' ')"
echo "abbey       : $(dig @$PRAB +short abbey.$DOMAIN A)"
echo "alpha TXT   : $(dig @$PRAB +short alpha.$DOMAIN TXT)"
echo
echo "Kalau serial tedd belum sama: di TEDD jalankan"
echo "  killall named; named -c /etc/bind/named.conf"