#!/bin/sh

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

DOMAIN="k-03.com"
ROLE="${1:-$(hostname)}"
IPS="$(ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | tr '\n' ' ')"

case "$ROLE" in
penny)
    echo "[PENNY] IP node: $IPS"
    [ -f /etc/apache2/conf.d/penny-proxy.conf ] || { echo "Jalankan soal-11/setup-penny.sh dulu"; exit 1; }

    cat > /etc/apache2/conf.d/penny-redirect.conf <<EOF
<VirtualHost *:80>
    ServerName penny.$DOMAIN
    ServerAlias $IPS
    Redirect permanent / http://www.$DOMAIN/
</VirtualHost>
EOF

    httpd -t || exit 1
    killall httpd 2>/dev/null
    sleep 1
    rm -f /run/apache2/httpd.pid
    mkdir -p /run/apache2
    httpd
    sleep 2

    echo
    echo "VERIFIKASI (harus 301 + Location: http://www.$DOMAIN/)"
    for H in penny.$DOMAIN $IPS; do
        echo "--- Host: $H"
        curl -s -I -H "Host: $H" http://127.0.0.1/ | grep -iE '^HTTP|^Location'
    done
    echo "--- Host: www.$DOMAIN (harus TIDAK redirect)"
    curl -s -I -H "Host: www.$DOMAIN" http://127.0.0.1/ | grep -iE '^HTTP|^Location'
    ;;

abbey)
    echo "[ABBEY] IP node: $IPS"
    [ -f /etc/nginx/http.d/abbey.conf ] || { echo "Jalankan soal-11/setup-abbey.sh dulu"; exit 1; }

    sed -i "s/ abbey\.$DOMAIN//" /etc/nginx/http.d/abbey.conf

    cat > /etc/nginx/http.d/abbey-redirect.conf <<EOF
server {
    listen 80;
    server_name abbey.$DOMAIN $IPS;
    return 302 http://static.$DOMAIN\$request_uri;
}
EOF

    nginx -t || exit 1
    nginx -s reload 2>/dev/null || { mkdir -p /run/nginx; nginx; }
    sleep 1

    echo
    echo "=== VERIFIKASI (harus 302 + Location: http://static.$DOMAIN/) ==="
    for H in abbey.$DOMAIN $IPS; do
        echo "--- Host: $H"
        curl -s -I -H "Host: $H" http://127.0.0.1/ | grep -iE '^HTTP|^Location'
    done
    ;;

*)
    echo "Pakai: sh script.sh penny|abbey"
    exit 1
    ;;
esac
