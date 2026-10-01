#!/bin/sh

DOMAIN="k-03.com"
VAULT1="10.65.3.5"      # obladi
VAULT2="10.65.3.4"      # desmond

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

start_svc() {
    if command -v rc-service >/dev/null 2>&1; then
        rc-update add "$1" default
        rc-service "$1" restart
    else
        echo "(OpenRC tidak ada, $1 dijalankan manual)"
        eval "$2"
    fi
}

echo "[1/4] Install Apache + modul proxy..."
apk update
apk add apache2 apache2-proxy || { echo "Gagal apk add (cek DNS/internet)"; exit 1; }

echo "[2/4] Aktifkan modul..."
enable_mod() {
    if grep -rqE "^[[:space:]]*LoadModule $1 " /etc/apache2/; then return; fi
    if grep -qE "^#[[:space:]]*LoadModule $1 " /etc/apache2/httpd.conf; then
        sed -i -E "s|^#[[:space:]]*(LoadModule $1 .*)|\1|" /etc/apache2/httpd.conf
    else
        echo "LoadModule $1 modules/$2" >> /etc/apache2/conf.d/00-modules-mesh.conf
    fi
}
while read -r name file; do
    enable_mod "$name" "$file"
done <<EOF
proxy_module mod_proxy.so
proxy_http_module mod_proxy_http.so
proxy_balancer_module mod_proxy_balancer.so
lbmethod_byrequests_module mod_lbmethod_byrequests.so
slotmem_shm_module mod_slotmem_shm.so
headers_module mod_headers.so
EOF

echo "[3/4] Tulis konfigurasi proxy..."
cat > /etc/apache2/conf.d/penny-proxy.conf <<'EOF'
ServerName penny.@DOMAIN@

<Proxy "balancer://vault">
    BalancerMember "http://@V1@:80"
    BalancerMember "http://@V2@:80"
    ProxySet lbmethod=byrequests
</Proxy>

<VirtualHost *:80>
    ServerName www.@DOMAIN@
    ServerAlias @DOMAIN@

    ProxyRequests Off
    # Meneruskan header Host asli (bukan alamat backend)
    ProxyPreserveHost On
    # Meneruskan IP asli pengunjung
    RequestHeader set X-Real-IP "expr=%{REMOTE_ADDR}"
    # Bukti distribusi: backend mana yang melayani (terlihat di respons)
    Header always set X-Served-By "%{BALANCER_WORKER_NAME}e"

    ProxyPass / balancer://vault/
    ProxyPassReverse / balancer://vault/
</VirtualHost>
EOF

sed -i \
    -e "s/@DOMAIN@/${DOMAIN}/g" \
    -e "s/@V1@/${VAULT1}/g" \
    -e "s/@V2@/${VAULT2}/g" \
    /etc/apache2/conf.d/penny-proxy.conf

echo "[4/4] Validasi, restart, autostart..."
httpd -t || exit 1
killall httpd 2>/dev/null
sleep 1
rm -f /run/apache2/httpd.pid
mkdir -p /run/apache2
start_svc apache2 "httpd"

echo
echo "Verifikasi (lokal di penny)"
sleep 2
echo "6 request ke penny. Header X-Served-By harus bergantian 10.65.3.5 / 10.65.3.4:"
for i in 1 2 3 4 5 6; do
    OUT=$(curl -s -m 5 -o /dev/null -D - -H "Host: www.${DOMAIN}" http://127.0.0.1/ \
          | grep -iE '^HTTP|^X-Served-By' | tr -d '\r' | tr '\n' ' ')
    echo "${OUT:-(tidak ada respons - cek: ps | grep httpd)}"
done
echo
echo "Kalau HTTP 502/503: backend tidak terjangkau. Tes langsung:"
echo "  curl -I http://${VAULT1}/   dan   curl -I http://${VAULT2}/"