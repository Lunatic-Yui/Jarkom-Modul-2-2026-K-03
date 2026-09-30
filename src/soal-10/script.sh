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
#
# CATATAN:
# File ini berisi command untuk beberapa node.
# Jalankan hanya bagian yang sesuai pada node terkait.
# ============================================================


# ============================================================
# [OBLADA]
# Perbaikan jaringan
#
# Pada topologi GNS3, Oblada terhubung ke Switch3 melalui eth1.
# IP 10.65.3.3/24 sebelumnya berada pada eth0 sehingga
# komunikasi jaringan tidak berjalan dengan benar.
# ============================================================

ip addr del 10.65.3.3/24 dev eth0 2>/dev/null || true

ip addr show eth1 | grep -q '10.65.3.3/24' || \
ip addr add 10.65.3.3/24 dev eth1

ip route del default 2>/dev/null || true
ip route add default via 10.65.3.1 dev eth1


# ============================================================
# [OBLADA]
# Route langsung menuju subnet DNS
#
# Route ditambahkan untuk mencegah ICMP Redirect ketika
# Oblada mengakses PRAB/TEDD pada jaringan 10.65.2.0/24.
# ============================================================

ip route show | grep -q '^10.65.2.0/24 dev eth1' || \
ip route add 10.65.2.0/24 dev eth1


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
# Install Nginx dan PHP-FPM
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
#
# Default virtual host tidak perlu dihapus.
# Pengujian dilakukan melalui hostname oblada.k-03.com.
# ============================================================

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
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass 127.0.0.1:9000;
    }
}
NGINX


# ============================================================
# [OBLADA]
# Validasi konfigurasi
# ============================================================

nginx -t
php-fpm84 -t


# ============================================================
# [OBLADA]
# Menjalankan layanan
# ============================================================

killall php-fpm84 2>/dev/null || true
php-fpm84

killall nginx 2>/dev/null || true
nginx


# ============================================================
# [OBLADA]
# Verifikasi service
# ============================================================

# ss -ltnp | grep -E ':80|:9000'

# Pengujian virtual host lokal:
#
# curl -s -H 'Host: oblada.k-03.com' \
# http://127.0.0.1/ | grep -E '<h1>|Server:'
#
# curl -s -H 'Host: oblada.k-03.com' \
# http://127.0.0.1/profil | grep -E '<h1>|Server:'


# ============================================================
# [OBLADA]
# Verifikasi menggunakan hostname
# ============================================================

# host oblada.k-03.com

# curl -s http://oblada.k-03.com/ \
# | grep -E '<h1>|Server:'

# curl -s http://oblada.k-03.com/profil \
# | grep -E '<h1>|Server:'


# ============================================================
# [MOLLY]
# Route langsung menuju subnet DNS
#
# Molly menggunakan eth0 untuk jaringan 10.65.3.0/24.
# Route ini mencegah ICMP Redirect ketika mengakses
# PRAB/TEDD pada jaringan 10.65.2.0/24.
# ============================================================

ip route show | grep -q '^10.65.2.0/24 dev eth0' || \
ip route add 10.65.2.0/24 dev eth0


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
# Install Nginx dan PHP-FPM
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
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass 127.0.0.1:9000;
    }
}
NGINX


# ============================================================
# [MOLLY]
# Validasi konfigurasi
# ============================================================

nginx -t
php-fpm84 -t


# ============================================================
# [MOLLY]
# Menjalankan layanan
# ============================================================

killall php-fpm84 2>/dev/null || true
php-fpm84

killall nginx 2>/dev/null || true
nginx


# ============================================================
# [MOLLY]
# Verifikasi service
# ============================================================

# ss -ltnp | grep -E ':80|:9000'

# Pengujian virtual host lokal:
#
# curl -s -H 'Host: molly.k-03.com' \
# http://127.0.0.1/ | grep -E '<h1>|Server:'
#
# curl -s -H 'Host: molly.k-03.com' \
# http://127.0.0.1/profil | grep -E '<h1>|Server:'


# ============================================================
# [MOLLY]
# Verifikasi menggunakan hostname
# ============================================================

# host molly.k-03.com

# curl -s http://molly.k-03.com/ \
# | grep -E '<h1>|Server:'

# curl -s http://molly.k-03.com/profil \
# | grep -E '<h1>|Server:'


# ============================================================
# [CLIENT - ALPHA]
# Verifikasi final kedua web server Core
# ============================================================

# curl -s http://oblada.k-03.com/ \
# | grep -E '<h1>|Server:'

# curl -s http://oblada.k-03.com/profil \
# | grep -E '<h1>|Server:'

# curl -s http://molly.k-03.com/ \
# | grep -E '<h1>|Server:'

# curl -s http://molly.k-03.com/profil \
# | grep -E '<h1>|Server:'


# ============================================================
# HASIL YANG DIHARAPKAN
# ============================================================

# OBLADA
#
# Halaman Beranda
# Server: oblada
#
# Halaman Profil
# Server: oblada
#
#
# MOLLY
#
# Halaman Beranda
# Server: molly
#
# Halaman Profil
# Server: molly
#
#
# PHP harus diproses oleh PHP-FPM pada:
# 127.0.0.1:9000
#
# Nginx berjalan pada:
# port 80
#
# Path /profil harus dapat digunakan tanpa menulis
# ekstensi .php.
#
# Oblada menggunakan:
# 10.65.3.3/24 pada eth1
#
# Molly menggunakan:
# 10.65.3.2/24 pada eth0
#
# Kedua node mempunyai route langsung menuju:
# 10.65.2.0/24
#
# sehingga komunikasi menuju DNS PRAB/TEDD stabil.
