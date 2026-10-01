#!/bin/sh

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

DOMAIN="k-03.com"
ROLE="${1:-$(hostname)}"

case "$ROLE" in
penny)
    CONF="/etc/apache2/conf.d/penny-proxy.conf"
    [ -f "$CONF" ] || { echo "Jalankan soal-11/setup-penny.sh dulu"; exit 1; }

    enable_mod() {
        if grep -rqE "^[[:space:]]*LoadModule $1 " /etc/apache2/; then return; fi
        if grep -qE "^#[[:space:]]*LoadModule $1 " /etc/apache2/httpd.conf; then
            sed -i -E "s|^#[[:space:]]*(LoadModule $1 .*)|\1|" /etc/apache2/httpd.conf
        else
            echo "LoadModule $1 modules/$2" >> /etc/apache2/conf.d/00-modules-mesh.conf
        fi
    }

    echo "[1/4] Install PHP-FPM..."
    apk update
    apk add apache2 apache2-proxy php84 php84-fpm curl || { echo "Gagal apk add"; exit 1; }

    enable_mod alias_module mod_alias.so
    enable_mod proxy_module mod_proxy.so
    enable_mod proxy_fcgi_module mod_proxy_fcgi.so

    echo "[2/4] Buat aplikasi /var/www/eternal..."
    mkdir -p /var/www/eternal
    cat > /var/www/eternal/index.php <<'EOF'
<!DOCTYPE html>
<html><head><title>Eternal</title></head>
<body>
<h1>Eternal (PHP aktif)</h1>
<p>Server: <?php echo gethostname(); ?></p>
<p>PHP versi: <?php echo PHP_VERSION; ?></p>
<p>Waktu server: <?php echo date('Y-m-d H:i:s'); ?></p>
</body></html>
EOF
    chmod -R a+rX /var/www/eternal

    sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' /etc/php84/php-fpm.d/www.conf

    echo "[3/4] Tulis konfigurasi /eternal..."
    mkdir -p /etc/apache2/conf.d/penny-vhost.d
    if ! grep -q 'penny-vhost.d' "$CONF"; then
        awk '/ProxyPass \/ balancer/ && !d {print "    IncludeOptional /etc/apache2/conf.d/penny-vhost.d/*.inc"; d=1} {print}' \
            "$CONF" > "$CONF.new" && mv "$CONF.new" "$CONF"
    fi

    cat > /etc/apache2/conf.d/penny-vhost.d/eternal.inc <<'EOF'
# /eternal berdiri sendiri: tidak diproxy ke vault, PHP dirender via PHP-FPM
ProxyPass /eternal !
Alias /eternal /var/www/eternal
<Directory "/var/www/eternal">
    Options None
    AllowOverride None
    Require all granted
    DirectoryIndex index.php index.html
    <FilesMatch "\.php$">
        SetHandler "proxy:fcgi://127.0.0.1:9000"
    </FilesMatch>
</Directory>
EOF

    echo "[4/4] Validasi & jalankan layanan..."
    php-fpm84 -t || exit 1
    httpd -t || exit 1
    killall php-fpm84 2>/dev/null
    sleep 1
    php-fpm84
    killall httpd 2>/dev/null
    sleep 1
    rm -f /run/apache2/httpd.pid
    mkdir -p /run/apache2
    httpd
    sleep 2

    echo
    echo "VERIFIKASI (harus tampil 'PHP aktif' & versi PHP, BUKAN tag <?php)"
    curl -s -H "Host: www.$DOMAIN" http://127.0.0.1/eternal/
    echo
    echo "Dari client: curl http://www.$DOMAIN/eternal/"
    ;;

abbey)
    CONF="/etc/nginx/http.d/abbey.conf"
    [ -f "$CONF" ] || { echo "Jalankan soal-11/setup-abbey.sh dulu"; exit 1; }

    echo "[1/3] Buat konten statis /var/www/orion..."
    mkdir -p /var/www/orion
    cat > /var/www/orion/index.html <<'EOF'
<!DOCTYPE html>
<html><head><title>Orion</title></head>
<body><h1>Orion (statis)</h1><p>Dilayani langsung oleh Abbey, tanpa PHP.</p></body></html>
EOF
    echo "File statis Orion" > /var/www/orion/info.txt
    chmod -R a+rX /var/www/orion

    echo "[2/3] Tulis konfigurasi /orion..."
    mkdir -p /etc/nginx/abbey.d
    if ! grep -q 'abbey.d' "$CONF"; then
        awk '/^[[:space:]]*server_name/ && !d {print; print "    include /etc/nginx/abbey.d/*.conf;"; d=1; next} {print}' \
            "$CONF" > "$CONF.new" && mv "$CONF.new" "$CONF"
    fi

    cat > /etc/nginx/abbey.d/orion.conf <<'EOF'
location = /orion {
    return 301 $scheme://$host/orion/;
}
location /orion/ {
    alias /var/www/orion/;
    index index.html;
}
EOF

    echo "[3/3] Validasi & reload nginx..."
    nginx -t || exit 1
    nginx -s reload 2>/dev/null || { mkdir -p /run/nginx; nginx; }
    sleep 1

    echo
    echo "VERIFIKASI"
    curl -s -H "Host: static.$DOMAIN" http://127.0.0.1/orion/
    echo
    curl -s -H "Host: static.$DOMAIN" http://127.0.0.1/orion/info.txt
    echo
    echo "Dari client: curl http://static.$DOMAIN/orion/"
    ;;

*)
    echo "Pakai: sh script.sh penny|abbey"
    exit 1
    ;;
esac
