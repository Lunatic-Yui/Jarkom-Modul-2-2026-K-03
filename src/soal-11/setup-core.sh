#!/bin/sh

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

CONF=/etc/nginx/http.d/core.conf
if [ -f "$CONF" ] && ! grep -q 'static.k-03.com' "$CONF"; then
    sed -i 's/^\([[:space:]]*server_name\)\(.*\);/\1\2 static.k-03.com;/' "$CONF"
fi

cat > /etc/nginx/http.d/hdr.conf <<'EOF'
log_format hdr '$host $http_x_real_ip';
access_log /var/log/nginx/hdr.log hdr;
EOF

if nginx -t; then
    nginx -s reload 2>/dev/null || { mkdir -p /run/nginx; nginx; }
else
    echo "Config nginx error"; exit 1
fi

echo
echo "Selesai. Dari client (alpha) jalankan:  curl http://static.k-03.com/"
echo "Lalu di node ini:  tail /var/log/nginx/hdr.log"
echo "Harus muncul:  static.k-03.com <IP client>   (bukan IP abbey)"
