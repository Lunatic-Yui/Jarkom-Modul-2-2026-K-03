#!/bin/sh

# ============================================================
# SOAL 10
# Web Dinamis Area Core menggunakan Nginx + PHP-FPM
#
# OBLADA : 10.65.3.3
# MOLLY  : 10.65.3.2
#
# Target:
# http://oblada.k-03.com/
# http://oblada.k-03.com/profil
#
# http://molly.k-03.com/
# http://molly.k-03.com/profil
# ============================================================


# ============================================================
# [OBLADA]
# Perbaikan interface jaringan
#
# Pada topologi GNS3, Oblada terhubung ke Switch3 melalui eth1.
# Oleh karena itu IP 10.65.3.3/24 dipasang pada eth1.
# ============================================================

ip addr del 10.65.3.3/24 dev eth0 2>/dev/null || true

ip addr show eth1 | grep -q '10.65.3.3/24' || \
ip addr add 10.65.3.3/24 dev eth1

ip route del default 2>/dev/null || true
ip route add default via 10.65.3.1 dev eth1

ip neigh flush all


# ============================================================
# [OBLADA]
# Konfigurasi resolver
# ============================================================

cat > /etc/resolv.conf <<'EOF'
nameserver 10.65.2.3
nameserver 10.65.2.2
nameserver 192.168.122.1
EOF


# ============================================================
# [OBLADA]
# Install Nginx, PHP 8.4, dan PHP-FPM
# ============================================================

apk update
apk add nginx php84 php84-fpm


# ============================================================
# [OBLADA]
# Membuat halaman web dinamis
# ============================================================

mkdir -p /var/www/core

cat > /var/www/core/index.php <<'PHP'
<!DOCTYPE html>
<html>
<head>
    <title>Beranda Core K-03</title>
</head>
<body>
    <h1>Halaman Beranda</h1>
    <p>Core Web K-03</p>
    <p>Server: <?php echo gethostname(); ?></p>
    <a href="/profil">Profil</a>
</body>
</html>
PHP

cat > /var/www/core/profil.php <<'PHP'
<!DOCTYPE html>
<html>
<head>
    <title>Profil Core K-03</title>
</head>
<body>
    <h1>Halaman Profil</h1>
    <p>Profil aplikasi Core K-03</p>
    <p>Server: <?php echo gethostname(); ?></p>
    <a href="/">Beranda</a>
</body>
</html>
PHP


# ============================================================
# [OBLADA]
# Konfigurasi PHP-FPM
# ============================================================

sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' \
/etc/php84/php-fpm.d/www.conf


# ============================================================
# [OBLADA]
# Konfigurasi Nginx
# ============================================================

rm -f /etc/nginx/http.d/default.conf

cat > /etc/nginx/http.d/core.conf <<'NGINX'
server {
    listen 80;

    server_name oblada.k-03.com core.k-03.com;

    root /var/www/core;
    index index.php;

    rewrite ^/profil/?$ /profil.php last;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME \
        $document_root$fastcgi_script_name;

        fastcgi_pass 127.0.0.1:9000;
    }
}
NGINX


# ============================================================
# [OBLADA]
# Validasi dan menjalankan layanan
# ============================================================

nginx -t

killall php-fpm84 2>/dev/null || true
php-fpm84

killall nginx 2>/dev/null || true
nginx


# ============================================================
# [OBLADA]
# Verifikasi lokal
# ============================================================

# curl http://127.0.0.1/
# curl http://127.0.0.1/profil


# ============================================================
# [MOLLY]
# Konfigurasi resolver
# ============================================================

cat > /etc/resolv.conf <<'EOF'
nameserver 10.65.2.3
nameserver 10.65.2.2
nameserver 192.168.122.1
EOF


# ============================================================
# [MOLLY]
# Install Nginx, PHP 8.4, dan PHP-FPM
# ============================================================

apk update
apk add nginx php84 php84-fpm


# ============================================================
# [MOLLY]
# Membuat halaman web dinamis
# ============================================================

mkdir -p /var/www/core

cat > /var/www/core/index.php <<'PHP'
<!DOCTYPE html>
<html>
<head>
    <title>Beranda Core K-03</title>
</head>
<body>
    <h1>Halaman Beranda</h1>
    <p>Core Web K-03</p>
    <p>Server: <?php echo gethostname(); ?></p>
    <a href="/profil">Profil</a>
</body>
</html>
PHP

cat > /var/www/core/profil.php <<'PHP'
<!DOCTYPE html>
<html>
<head>
    <title>Profil Core K-03</title>
</head>
<body>
    <h1>Halaman Profil</h1>
    <p>Profil aplikasi Core K-03</p>
    <p>Server: <?php echo gethostname(); ?></p>
    <a href="/">Beranda</a>
</body>
</html>
PHP


# ============================================================
# [MOLLY]
# Konfigurasi PHP-FPM
# ============================================================

sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' \
/etc/php84/php-fpm.d/www.conf


# ============================================================
# [MOLLY]
# Konfigurasi Nginx
# ============================================================

rm -f /etc/nginx/http.d/default.conf

cat > /etc/nginx/http.d/core.conf <<'NGINX'
server {
    listen 80;

    server_name molly.k-03.com core.k-03.com;

    root /var/www/core;
    index index.php;

    rewrite ^/profil/?$ /profil.php last;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME \
        $document_root$fastcgi_script_name;

        fastcgi_pass 127.0.0.1:9000;
    }
}
NGINX


# ============================================================
# [MOLLY]
# Validasi dan menjalankan layanan
# ============================================================

nginx -t

killall php-fpm84 2>/dev/null || true
php-fpm84

killall nginx 2>/dev/null || true
nginx


# ============================================================
# [MOLLY]
# Verifikasi lokal
# ============================================================

# curl http://127.0.0.1/
# curl http://127.0.0.1/profil


# ============================================================
# [CLIENT - contoh: ALPHA]
# Verifikasi menggunakan hostname
# ============================================================

# curl http://oblada.k-03.com/
# curl http://oblada.k-03.com/profil

# curl http://molly.k-03.com/
# curl http://molly.k-03.com/profil


# ============================================================
# HASIL YANG DIHARAPKAN
# ============================================================

# OBLADA:
# Halaman Beranda
# Server: oblada
#
# Halaman Profil
# Server: oblada
#
# MOLLY:
# Halaman Beranda
# Server: molly
#
# Halaman Profil
# Server: molly
#
# Path /profil harus dapat diakses tanpa ".php".
# PHP harus benar-benar dieksekusi oleh PHP-FPM,
# bukan menampilkan source code PHP.
