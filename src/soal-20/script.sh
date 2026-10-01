#!/bin/sh

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

DOMAIN="k-03.com"
ZONE="/var/bind/db.$DOMAIN"
ABBEY_IP="10.65.4.2"
PRAB="10.65.2.3"
TEDD="10.65.2.2"
IFACES="${IFACES:-/etc/network/interfaces}"
ROLE="${1:-$(hostname)}"

if command -v rc-update >/dev/null 2>&1; then MODE="openrc"; else MODE="ifup"; fi
echo "SOAL 20 pada node: $ROLE | mode autostart: $MODE"

is_running() {   
    for d in /proc/[0-9]*; do
        [ "$(cat "$d/comm" 2>/dev/null)" = "$1" ] && return 0
    done
    return 1
}

svc_cmd() {      
    case "$1" in
        named)     echo 'named -c /etc/bind/named.conf' ;;
        apache2)   echo 'mkdir -p /run/apache2; rm -f /run/apache2/httpd.pid; httpd' ;;
        nginx)     echo 'mkdir -p /run/nginx; nginx' ;;
        php-fpm84) echo 'php-fpm84' ;;
    esac
}

add_up() {      
    tag="$1"; cmd="$2"
    [ -f "$IFACES" ] || { echo "!! $IFACES tidak ada"; return 1; }
    if grep -q "^[[:space:]]*# auto-$tag\$" "$IFACES"; then
        echo "   (baris up '$tag' sudah ada di $IFACES)"; return 0
    fi
    IFN=$(awk '$1=="iface" && $2!="lo"{print $2; exit}' "$IFACES")
    [ -n "$IFN" ] || { echo "!! stanza interface tidak ditemukan di $IFACES"; return 1; }
    awk -v ifn="$IFN" -v tag="$tag" -v cmd="$cmd" '
        { print }
        $1=="iface" && $2==ifn && !d { print "    # auto-" tag; print "    up " cmd; d=1 }
    ' "$IFACES" > "$IFACES.new" && mv "$IFACES.new" "$IFACES"
    echo "   + baris up '$tag' ditambahkan ke $IFACES ($IFN)"
}

enable_svc() {   
    svc="$1"; proc="$2"
    if [ "$MODE" = "openrc" ]; then
        if [ ! -x "/etc/init.d/$svc" ]; then
            echo "!! /etc/init.d/$svc tidak ada (paket belum ter-install?)"; return 1
        fi
        killall "$proc" 2>/dev/null
        sleep 1
        rm -f /run/apache2/httpd.pid /run/nginx/nginx.pid /run/named/named.pid /var/run/named/named.pid
        rc-update add "$svc" default >/dev/null 2>&1
        rc-service "$svc" restart >/dev/null 2>&1 || rc-service "$svc" start
        sleep 2
        if rc-service "$svc" status >/dev/null 2>&1 && rc-update show default | grep -qw "$svc"; then
            echo "OK   $svc : berjalan + autostart"
        else
            echo "GAGAL $svc : cek 'rc-service $svc status' dan log-nya"
        fi
    else
        cmd=$(svc_cmd "$svc")
        command -v "$proc" >/dev/null 2>&1 || { echo "!! $proc tidak ter-install"; return 1; }
        killall "$proc" 2>/dev/null
        sleep 1
        rm -f /run/apache2/httpd.pid /run/nginx/nginx.pid /run/named/named.pid /var/run/named/named.pid
        sh -c "$cmd" >/dev/null 2>&1
        sleep 2
        add_up "$svc" "$cmd >/dev/null 2>&1 || true"
        if is_running "$proc"; then
            echo "OK   $svc : berjalan + autostart (up-line)"
        else
            echo "GAGAL $svc : proses tidak jalan, coba manual: $cmd"
        fi
    fi
}

fix_bind_perms() {   
    [ "$MODE" = "openrc" ] || return 0
    id named >/dev/null 2>&1 || return 0
    [ -d /var/bind ] || return 0
    chgrp -R named /var/bind
    find /var/bind -type d -exec chmod 775 {} +
    find /var/bind -type f -exec chmod 664 {} +
}

http() { printf '   %-62s' "$*"; curl -s -o /dev/null -m 5 -w '%{http_code}\n' "$@"; }

case "$ROLE" in
prab)
    echo "[1/3] Batalkan soal 18: abbey -> $ABBEY_IP (TTL normal)"
    if [ -f "$ZONE" ]; then
        sed -i -E "/^abbey(\.$DOMAIN\.)?[[:space:]]+([0-9]+[[:space:]]+)?(IN[[:space:]]+)?A[[:space:]]/d" "$ZONE"
        [ -n "$(tail -c1 "$ZONE")" ] && echo >> "$ZONE"
        printf 'abbey    IN    A    %s\n' "$ABBEY_IP" >> "$ZONE"
        CUR=$(awk '/SOA/{f=1;next} f&&/^[[:space:]]*[0-9]+/{print $1;exit}' "$ZONE")
        NEW=$((CUR + 1))
        awk -v n="$NEW" '/SOA/{f=1;print;next} f&&!d&&/^[[:space:]]*[0-9]+/{sub(/[0-9]+/,n);d=1} {print}' \
            "$ZONE" > "$ZONE.new" && mv "$ZONE.new" "$ZONE"
        echo "   serial: $CUR -> $NEW"
        named-checkzone "$DOMAIN" "$ZONE" || exit 1
    fi
    echo "[2/3] named -> autostart"
    fix_bind_perms
    enable_svc named named
    sleep 3
    echo "[3/3] Verifikasi"
    echo "   abbey.$DOMAIN -> $(dig @127.0.0.1 +short abbey.$DOMAIN A) (harus $ABBEY_IP)"
    echo "   serial prab: $(dig @$PRAB +short $DOMAIN SOA | awk '{print $3}')"
    echo "   serial tedd: $(dig @$TEDD +short $DOMAIN SOA | awk '{print $3}')  (harus sama)"
    ;;
tedd)
    fix_bind_perms
    enable_svc named named
    sleep 3
    echo "   serial prab: $(dig @$PRAB +short $DOMAIN SOA | awk '{print $3}')"
    echo "   serial tedd: $(dig @$TEDD +short $DOMAIN SOA | awk '{print $3}')  (harus sama)"
    echo "   abbey.$DOMAIN @tedd -> $(dig @$TEDD +short abbey.$DOMAIN A) (harus $ABBEY_IP)"
    ;;
penny)
    enable_svc apache2 httpd
    enable_svc php-fpm84 php-fpm84
    http -H "Host: www.$DOMAIN" http://127.0.0.1/
    http -H "Host: www.$DOMAIN" http://127.0.0.1/admin/
    http -H "Host: www.$DOMAIN" http://127.0.0.1/eternal/
    ;;
abbey)
    enable_svc nginx nginx
    http -H "Host: static.$DOMAIN" http://127.0.0.1/
    http -H "Host: static.$DOMAIN" http://127.0.0.1/orion/
    ;;
obladi|desmond)
    enable_svc apache2 httpd
    http http://127.0.0.1/arsip/
    ;;
oblada|molly)
    enable_svc nginx nginx
    enable_svc php-fpm84 php-fpm84
    http -H "Host: core.$DOMAIN" http://127.0.0.1/
    http -H "Host: core.$DOMAIN" http://127.0.0.1/profil
    ;;
*)
    echo "Node '$ROLE' tidak menjalankan service yang perlu di-autostart."
    echo "Atau jalankan dengan argumen: sh auto.sh prab|tedd|penny|abbey|obladi|desmond|oblada|molly"
    ;;
esac

echo
if [ "$MODE" = "openrc" ]; then
    echo "Service autostart di node ini:"
    rc-update show default
else
    echo "Baris autostart di $IFACES:"
    grep -A1 '# auto-' "$IFACES"
fi
echo
echo "Hostname: $(hostname) | resolv.conf:"
cat /etc/resolv.conf
echo