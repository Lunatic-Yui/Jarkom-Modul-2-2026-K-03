#!/bin/sh

DOMAIN="k-03.com"
CORE1="10.65.3.3"       # oblada
CORE2="10.65.3.2"       # molly

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

echo "[1/3] Install nginx..."
apk update
apk add nginx || { echo "Gagal apk add (cek DNS/internet)"; exit 1; }

echo "[2/3] Tulis konfigurasi proxy..."
rm -f /etc/nginx/http.d/default.conf

cat > /etc/nginx/http.d/abbey.conf <<'EOF'
upstream core_backend {
    server @CORE1@:80;
    server @CORE2@:80;
}

server {
    listen 80 default_server;
    server_name static.@DOMAIN@ abbey.@DOMAIN@ _;

    location / {
        proxy_pass http://core_backend;
        # Meneruskan header Host asli dan IP asli pengunjung
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # Bukti distribusi: backend mana yang melayani (terlihat di respons)
        add_header X-Served-By $upstream_addr always;
    }
}
EOF

sed -i \
    -e "s/@DOMAIN@/${DOMAIN}/g" \
    -e "s/@CORE1@/${CORE1}/g" \
    -e "s/@CORE2@/${CORE2}/g" \
    /etc/nginx/http.d/abbey.conf

echo "[3/3] Validasi, restart, autostart..."
nginx -t || exit 1
killall nginx 2>/dev/null
sleep 1
mkdir -p /run/nginx
start_svc nginx "nginx"

echo
echo "Verifikasi (lokal di abbey)"
sleep 2
echo "6 request ke abbey. Header X-Served-By harus bergantian 10.65.3.3 / 10.65.3.2:"
for i in 1 2 3 4 5 6; do
    OUT=$(curl -s -m 5 -o /dev/null -D - -H "Host: static.${DOMAIN}" http://127.0.0.1/ \
          | grep -iE '^HTTP|^X-Served-By' | tr -d '\r' | tr '\n' ' ')
    echo "${OUT:-(tidak ada respons - cek: ps | grep nginx)}"
done
echo
echo "Kalau HTTP 502: backend tidak terjangkau. Tes langsung:"
echo "  curl -I http://${CORE1}/   dan   curl -I http://${CORE2}/"