#!/bin/sh

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

DOMAIN="k-03.com"
AUTH_USER="prabs"
AUTH_PASS='pakar_pinter_jadi_gob***'
HTPASSWD="/etc/apache2/.htpasswd"
CONF="/etc/apache2/conf.d/penny-proxy.conf"

enable_mod() {
    if grep -rqE "^[[:space:]]*LoadModule $1 " /etc/apache2/; then return; fi
    if grep -qE "^#[[:space:]]*LoadModule $1 " /etc/apache2/httpd.conf; then
        sed -i -E "s|^#[[:space:]]*(LoadModule $1 .*)|\1|" /etc/apache2/httpd.conf
    else
        echo "LoadModule $1 modules/$2" >> /etc/apache2/conf.d/00-modules-mesh.conf
    fi
}

echo "[1/5] Install paket..."
apk update
apk add apache2 apache2-utils curl || { echo "Gagal apk add"; exit 1; }

echo "[2/5] Aktifkan modul auth..."
enable_mod alias_module mod_alias.so
enable_mod authn_file_module mod_authn_file.so
enable_mod auth_basic_module mod_auth_basic.so
enable_mod authz_user_module mod_authz_user.so

echo "[3/5] Buat user & halaman rahasia..."
htpasswd -bc "$HTPASSWD" "$AUTH_USER" "$AUTH_PASS"
chgrp apache "$HTPASSWD" 2>/dev/null
chmod 640 "$HTPASSWD"

mkdir -p /var/www/admin
cat > /var/www/admin/index.html <<'EOF'
<!DOCTYPE html>
<html><head><title>Admin</title></head>
<body><h1>Ruang Rahasia Sindikat</h1><p>Dokumen rahasia - hanya untuk admin.</p></body></html>
EOF
chmod -R a+rX /var/www/admin

echo "[4/5] Tulis konfigurasi /admin..."
[ -f "$CONF" ] || { echo "$CONF belum ada. Jalankan soal-11/setup-penny.sh dulu"; exit 1; }
mkdir -p /etc/apache2/conf.d/penny-vhost.d
if ! grep -q 'penny-vhost.d' "$CONF"; then
    awk '/ProxyPass \/ balancer/ && !d {print "    IncludeOptional /etc/apache2/conf.d/penny-vhost.d/*.inc"; d=1} {print}' \
        "$CONF" > "$CONF.new" && mv "$CONF.new" "$CONF"
fi

cat > /etc/apache2/conf.d/penny-vhost.d/admin.inc <<EOF
# /admin dilayani lokal oleh penny (tidak diproxy) + basic auth
ProxyPass /admin !
Alias /admin /var/www/admin
<Directory "/var/www/admin">
    AuthType Basic
    AuthName "Ruang Rahasia Sindikat"
    AuthUserFile $HTPASSWD
    Require valid-user
    Options None
    AllowOverride None
</Directory>
EOF

echo "[5/5] Validasi & restart Apache..."
httpd -t || exit 1
killall httpd 2>/dev/null
sleep 1
rm -f /run/apache2/httpd.pid
mkdir -p /run/apache2
httpd
sleep 2

echo
echo "=== VERIFIKASI ==="
code() { curl -s -o /dev/null -w '%{http_code}' -H "Host: www.$DOMAIN" "$@"; }
echo "Tanpa kredensial   (harus 401): $(code http://127.0.0.1/admin/)"
echo "Password salah     (harus 401): $(code -u "$AUTH_USER:salah" http://127.0.0.1/admin/)"
echo "Kredensial benar   (harus 200): $(code -u "$AUTH_USER:$AUTH_PASS" http://127.0.0.1/admin/)"
echo
echo "Dari client:  curl -i http://www.$DOMAIN/admin/"
echo "              curl -u 'prabs:pakar_pinter_jadi_gob***' http://www.$DOMAIN/admin/"
