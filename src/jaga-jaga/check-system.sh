#!/bin/sh

DOMAIN="k-03.com"
PRAB="10.65.2.3"
TEDD="10.65.2.2"
ABBEY_IP="10.65.4.2"
IFACES="${IFACES:-/etc/network/interfaces}"
ROLE="${1:-$(hostname)}"
PASS=0
FAIL=0

ok()  { printf '  [ OK ] %s\n' "$1"; PASS=$((PASS+1)); }
bad() { printf '  [FAIL] %s\n' "$1"; FAIL=$((FAIL+1)); }

eq() {   
    if [ "$2" = "$3" ]; then ok "$1 = $3"; else bad "$1: harusnya '$2', dapat '${3:-kosong}'"; fi
}
has() {  
    case "$3" in *"$2"*) ok "$1" ;; *) bad "$1 (tidak ada '$2' di '${3:-kosong}')" ;; esac
}
is_running() {
    for d in /proc/[0-9]*; do
        [ "$(cat "$d/comm" 2>/dev/null)" = "$1" ] && return 0
    done
    return 1
}
check_proc() {   
    if is_running "$2"; then ok "proses $1 berjalan"; else bad "proses $1 TIDAK berjalan"; fi
}
check_up() {     
    if command -v rc-update >/dev/null 2>&1; then
        if rc-update show default 2>/dev/null | grep -qw "$1"; then ok "autostart (openrc): $1"
        else bad "autostart (openrc) '$1' belum terdaftar"; fi
    else
        if grep -q "^[[:space:]]*# auto-$1\$" "$IFACES" 2>/dev/null; then ok "baris autostart '# auto-$1' ada di interfaces"
        else bad "baris autostart '# auto-$1' TIDAK ada di $IFACES (jalankan auto.sh)"; fi
    fi
}
http() {         
    d="$1"; e="$2"; shift 2
    c=$(curl -s -o /dev/null -m 6 -w '%{http_code}' "$@")
    case "|$e|" in *"|$c|"*) ok "$d -> HTTP $c" ;; *) bad "$d -> HTTP $c (harusnya $e)" ;; esac
}
check_resolv() {
    r=$(grep '^nameserver' /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ' ')
    eq "urutan resolver" "$PRAB $TEDD 192.168.122.1 " "$r"
}
ser() { dig @"$1" +short +time=2 +tries=1 "$DOMAIN" SOA 2>/dev/null | awk '{print $3}'; }

echo "=== CHECK SOAL 20 | node: $(hostname) | peran: $ROLE ==="

case "$ROLE" in
rootkit)
    eq "ip_forward (routing aktif)" "1" "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)"
    ;;
prab)
    check_resolv
    check_proc "named" named
    check_up named
    SP=$(ser 127.0.0.1)
    eq "serial SOA di prab = tedd" "$SP" "$(ser $TEDD)"
    has "www.$DOMAIN -> penny (10.65.5.2)" "10.65.5.2" "$(dig @127.0.0.1 +short www.$DOMAIN)"
    eq "abbey.$DOMAIN (soal 18 sudah dibatalkan)" "$ABBEY_IP" "$(dig @127.0.0.1 +short abbey.$DOMAIN A)"
    eq "TXT alpha" "alpha" "$(dig @127.0.0.1 +short alpha.$DOMAIN TXT | tr -d '"')"
    has "outbound CNAME ke http.badssl.com" "http.badssl.com" "$(dig @127.0.0.1 +short outbound.$DOMAIN CNAME)"
    ;;
tedd)
    check_resolv
    check_proc "named" named
    check_up named
    eq "serial SOA tedd = prab" "$(ser $PRAB)" "$(ser 127.0.0.1)"
    eq "abbey.$DOMAIN @tedd" "$ABBEY_IP" "$(dig @127.0.0.1 +short abbey.$DOMAIN A)"
    has "www.$DOMAIN @tedd -> 10.65.5.2" "10.65.5.2" "$(dig @127.0.0.1 +short www.$DOMAIN)"
    ;;
penny)
    check_resolv
    check_proc "apache (httpd)" httpd
    check_proc "php-fpm84" php-fpm84
    check_up apache2
    check_up php-fpm84
    http "www.$DOMAIN / (proxy ke vault)" 200 -H "Host: www.$DOMAIN" http://127.0.0.1/
    http "/admin tanpa kredensial" 401 -H "Host: www.$DOMAIN" http://127.0.0.1/admin/
    http "/admin kredensial benar" 200 -H "Host: www.$DOMAIN" -u 'prabs:pakar_pinter_jadi_gob***' http://127.0.0.1/admin/
    http "/eternal" 200 -H "Host: www.$DOMAIN" http://127.0.0.1/eternal/
    has "/eternal merender PHP" "PHP aktif" "$(curl -s -m 6 -H "Host: www.$DOMAIN" http://127.0.0.1/eternal/)"
    http "penny.$DOMAIN redirect permanen" 301 -H "Host: penny.$DOMAIN" http://127.0.0.1/
    ;;
abbey)
    check_resolv
    check_proc "nginx" nginx
    check_up nginx
    http "static.$DOMAIN / (proxy ke core)" 200 -H "Host: static.$DOMAIN" http://127.0.0.1/
    http "/orion statis" 200 -H "Host: static.$DOMAIN" http://127.0.0.1/orion/
    http "abbey.$DOMAIN redirect sementara" 302 -H "Host: abbey.$DOMAIN" http://127.0.0.1/
    ;;
obladi|desmond)
    check_resolv
    check_proc "apache (httpd)" httpd
    check_up apache2
    http "/arsip/ (autoindex)" 200 http://127.0.0.1/arsip/
    ;;
oblada|molly)
    check_resolv
    check_proc "nginx" nginx
    check_proc "php-fpm84" php-fpm84
    check_up nginx
    check_up php-fpm84
    http "beranda core" 200 -H "Host: core.$DOMAIN" http://127.0.0.1/
    http "/profil (URL bersih)" 200 -H "Host: core.$DOMAIN" http://127.0.0.1/profil
    ;;
alpha|beta|gamma|delta|epsilon)
    check_resolv
    eq "TXT $ROLE.$DOMAIN" "$ROLE" "$(dig +short +time=3 +tries=1 $ROLE.$DOMAIN TXT | tr -d '"')"
    has "www.$DOMAIN -> 10.65.5.2" "10.65.5.2" "$(dig +short +time=3 +tries=1 www.$DOMAIN)"
    eq "abbey.$DOMAIN" "$ABBEY_IP" "$(dig +short +time=3 +tries=1 abbey.$DOMAIN A)"
    http "www.$DOMAIN" 200 http://www.$DOMAIN/
    http "static.$DOMAIN" 200 http://static.$DOMAIN/
    http "www.$DOMAIN/admin tanpa kredensial" 401 http://www.$DOMAIN/admin/
    http "www.$DOMAIN/admin kredensial benar" 200 -u 'prabs:pakar_pinter_jadi_gob***' http://www.$DOMAIN/admin/
    http "www.$DOMAIN/eternal" 200 http://www.$DOMAIN/eternal/
    http "static.$DOMAIN/orion" 200 http://static.$DOMAIN/orion/
    http "penny.$DOMAIN redirect 301" 301 http://penny.$DOMAIN/
    http "abbey.$DOMAIN redirect 302" 302 http://abbey.$DOMAIN/
    ;;
*)
    echo "Peran '$ROLE' tidak dikenal."
    echo "Pakai: sh check.sh rootkit|prab|tedd|penny|abbey|obladi|desmond|oblada|molly|alpha|beta|gamma|delta|epsilon"
    exit 2
    ;;
esac

echo
echo "HASIL: $PASS OK, $FAIL FAIL"
[ "$FAIL" -eq 0 ] && echo "=> Semua beres." || echo "=> Ada yang gagal: jalankan 'sh auto.sh' di node ini lalu restart lagi."
[ "$FAIL" -eq 0 ]