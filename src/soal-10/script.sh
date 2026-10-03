#!/bin/sh

# ============================================================
# K-03 - SOAL 10
# ============================================================

NODE="$(hostname)"

DOMAIN="k-03.com"

MASTER_IP="10.65.2.3"
SLAVE_IP="10.65.2.2"
EXTERNAL_DNS="192.168.122.1"

GATEWAY="10.65.3.1"


# ============================================================
# FUNGSI BANTUAN
# ============================================================

ok() {
    echo
    echo "[OK] $1"
}

fail() {
    echo
    echo "[GAGAL] $1"
    exit 1
}

garis() {
    echo
    echo "============================================================"
}


echo
echo "============================================================"
echo " K-03 - SOAL 10"
echo " Node terdeteksi: $NODE"
echo "============================================================"


# ============================================================
# CLIENT ALPHA
# ============================================================

if [ "$NODE" = "alpha" ]; then

    # ========================================================
    # STEP 1 - SET DNS CLIENT
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 1/4 - Mengatur DNS Alpha"
    echo

    echo "Command yang dijalankan:"
    echo "nameserver $MASTER_IP"
    echo "nameserver $SLAVE_IP"
    echo "nameserver $EXTERNAL_DNS"
    echo

    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF

    echo "Isi /etc/resolv.conf:"
    cat /etc/resolv.conf

    ok "Resolver Alpha siap."

    # ========================================================
    # STEP 1 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 2 - CEK DNS OBLADA DAN MOLLY
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/4 - Mengecek DNS Oblada dan Molly"
    echo

    if ! command -v host >/dev/null 2>&1; then

        echo "bind-tools belum tersedia."
        echo "Menjalankan:"
        echo "apk add bind-tools"
        echo

        apk add bind-tools \
            || fail "Gagal menginstall bind-tools."
    fi


    echo "Command:"
    echo "host oblada.$DOMAIN"
    echo

    host "oblada.$DOMAIN"

    echo
    echo "Command:"
    echo "host molly.$DOMAIN"
    echo

    host "molly.$DOMAIN"


    OBLADA_DNS="$(host "oblada.$DOMAIN" | awk '/has address/ {print $4}')"
    MOLLY_DNS="$(host "molly.$DOMAIN" | awk '/has address/ {print $4}')"


    echo
    echo "IP Oblada yang diharapkan : 10.65.3.3"
    echo "IP Oblada hasil DNS       : $OBLADA_DNS"
    echo
    echo "IP Molly yang diharapkan  : 10.65.3.2"
    echo "IP Molly hasil DNS        : $MOLLY_DNS"


    if [ "$OBLADA_DNS" = "10.65.3.3" ] && \
       [ "$MOLLY_DNS" = "10.65.3.2" ]; then

        ok "DNS Oblada dan Molly sesuai."

    else

        fail "DNS Oblada atau Molly tidak sesuai."

    fi

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - CEK WEB OBLADA
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/4 - Menguji web Oblada"
    echo


    if ! command -v curl >/dev/null 2>&1; then

        echo "curl belum tersedia."
        echo "Menjalankan:"
        echo "apk add curl"
        echo

        apk add curl \
            || fail "Gagal menginstall curl."
    fi


    echo "Command:"
    echo "curl -s http://oblada.$DOMAIN/"
    echo

    OBLADA_HOME="$(curl -s "http://oblada.$DOMAIN/")"

    echo "$OBLADA_HOME"


    echo
    echo "Command:"
    echo "curl -s http://oblada.$DOMAIN/profil"
    echo

    OBLADA_PROFILE="$(curl -s "http://oblada.$DOMAIN/profil")"

    echo "$OBLADA_PROFILE"


    if echo "$OBLADA_HOME" | grep -q "Halaman Beranda" && \
       echo "$OBLADA_HOME" | grep -q "Server: oblada" && \
       echo "$OBLADA_PROFILE" | grep -q "Halaman Profil"; then

        ok "Web Oblada berhasil diakses."

    else

        fail "Web Oblada belum berjalan dengan benar."

    fi

    # ========================================================
    # STEP 3 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 4 - CEK WEB MOLLY
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 4/4 - Menguji web Molly"
    echo


    echo "Command:"
    echo "curl -s http://molly.$DOMAIN/"
    echo

    MOLLY_HOME="$(curl -s "http://molly.$DOMAIN/")"

    echo "$MOLLY_HOME"


    echo
    echo "Command:"
    echo "curl -s http://molly.$DOMAIN/profil"
    echo

    MOLLY_PROFILE="$(curl -s "http://molly.$DOMAIN/profil")"

    echo "$MOLLY_PROFILE"


    if echo "$MOLLY_HOME" | grep -q "Halaman Beranda" && \
       echo "$MOLLY_HOME" | grep -q "Server: molly" && \
       echo "$MOLLY_PROFILE" | grep -q "Halaman Profil"; then

        ok "Web Molly berhasil diakses."

    else

        fail "Web Molly belum berjalan dengan benar."

    fi


    garis
    echo "HASIL AKHIR SOAL 10"
    echo "------------------------------------------------------------"
    echo "Oblada : http://oblada.$DOMAIN/"
    echo "Molly  : http://molly.$DOMAIN/"
    echo
    echo "[OK] DNS Oblada berhasil."
    echo "[OK] DNS Molly berhasil."
    echo "[OK] Web Oblada berhasil."
    echo "[OK] Web Molly berhasil."
    echo "[OK] Halaman /profil berhasil."
    garis

    echo
    echo "SOAL 10 - VERIFIKASI ALPHA SELESAI"
    echo

    exit 0

    # ========================================================
    # STEP 4 - SELESAI SAMPAI SINI
    # ========================================================
fi


# ============================================================
# CEK NODE SERVER
# ============================================================

if [ "$NODE" != "oblada" ] && [ "$NODE" != "molly" ]; then

    garis
    echo "[GAGAL] Script Soal 10 tidak digunakan pada node: $NODE"
    echo
    echo "Jalankan script ini pada:"
    echo "  - oblada"
    echo "  - molly"
    echo "  - alpha"
    garis

    exit 1
fi


# ============================================================
# MENENTUKAN KONFIGURASI BERDASARKAN NODE
# ============================================================

if [ "$NODE" = "oblada" ]; then

    SERVER_IP="10.65.3.3"
    INTERFACE="eth1"

fi


if [ "$NODE" = "molly" ]; then

    SERVER_IP="10.65.3.2"
    INTERFACE="eth0"

fi


# ============================================================
# STEP 1 - KONFIGURASI JARINGAN
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 1/9 - Memastikan konfigurasi jaringan $NODE"
echo


# ------------------------------------------------------------
# KHUSUS OBLADA
# ------------------------------------------------------------

if [ "$NODE" = "oblada" ]; then

    echo "Oblada harus menggunakan eth1."
    echo

    echo "Command yang diperlukan:"
    echo "ip addr del 10.65.3.3/24 dev eth0"
    echo "ip addr add 10.65.3.3/24 dev eth1"
    echo


    ip link set eth1 up


    if ip addr show eth0 | grep -q '10.65.3.3/24'; then

        echo "IP 10.65.3.3 masih berada pada eth0."
        echo "Memindahkan IP ke eth1..."

        ip addr del 10.65.3.3/24 dev eth0 \
            || fail "Gagal menghapus IP dari eth0."

    fi


    if ip addr show eth1 | grep -q '10.65.3.3/24'; then

        echo "IP 10.65.3.3/24 sudah tersedia pada eth1."

    else

        echo "Menambahkan 10.65.3.3/24 ke eth1..."

        ip addr add 10.65.3.3/24 dev eth1 \
            || fail "Gagal menambahkan IP pada eth1."

    fi


    echo
    echo "Memastikan default gateway melalui eth1..."


    if ip route show default | grep -q 'via 10.65.3.1 dev eth1'; then

        echo "Default gateway sudah benar."

    else

        ip route del default 2>/dev/null || true

        ip route add default via "$GATEWAY" dev eth1 \
            || fail "Gagal menambahkan default gateway."

    fi

fi


# ------------------------------------------------------------
# KHUSUS MOLLY
# ------------------------------------------------------------

if [ "$NODE" = "molly" ]; then

    echo "Molly menggunakan eth0."
    echo


    if ip addr show eth0 | grep -q '10.65.3.2/24'; then

        echo "IP 10.65.3.2/24 sudah tersedia pada eth0."

    else

        echo "Menambahkan IP 10.65.3.2/24 pada eth0..."

        ip addr add 10.65.3.2/24 dev eth0 \
            || fail "Gagal menambahkan IP Molly."

    fi

fi


echo
echo "Konfigurasi interface:"
echo

ip addr show "$INTERFACE"

echo
echo "Routing table:"
echo

ip route

ok "Konfigurasi interface $NODE siap."

# ============================================================
# STEP 1 - SELESAI SAMPAI SINI
# ========================================================


# ============================================================
# STEP 2 - ROUTE LANGSUNG KE DNS
# MULAI DARI SINI
# ========================================================

garis
echo "STEP 2/9 - Memastikan route menuju subnet DNS"
echo

echo "Route yang dibutuhkan:"
echo "10.65.2.0/24 dev $INTERFACE"
echo


if ip route show | grep -q "^10.65.2.0/24 dev $INTERFACE"; then

    echo "Route menuju DNS sudah tersedia."

else

    echo "Menambahkan route..."
    echo
    echo "Command:"
    echo "ip route add 10.65.2.0/24 dev $INTERFACE"
    echo

    ip route add 10.65.2.0/24 dev "$INTERFACE" \
        || fail "Gagal menambahkan route menuju DNS."

fi


echo
echo "Routing table:"
ip route


echo
echo "Menguji PRAB..."
echo
echo "Command:"
echo "ping -c 4 $MASTER_IP"
echo


if ping -c 4 "$MASTER_IP"; then

    ok "$NODE dapat menghubungi PRAB."

else

    fail "$NODE tidak dapat menghubungi PRAB."

fi

# ============================================================
# STEP 2 - SELESAI SAMPAI SINI
# ========================================================


# ============================================================
# STEP 3 - INSTALL NGINX DAN PHP
# MULAI DARI SINI
# ========================================================

garis
echo "STEP 3/9 - Memastikan Nginx dan PHP tersedia"
echo


echo "Menggunakan DNS eksternal sementara untuk instalasi paket."

cat > /etc/resolv.conf <<EOF
nameserver $EXTERNAL_DNS
EOF


if ! apk info -e nginx >/dev/null 2>&1; then

    echo
    echo "Nginx belum tersedia."
    echo "Command:"
    echo "apk add nginx"
    echo

    apk add nginx \
        || fail "Gagal menginstall Nginx."

else

    echo "Nginx sudah terinstall."

fi


if ! apk info -e php84 >/dev/null 2>&1; then

    echo
    echo "PHP 8.4 belum tersedia."
    echo "Command:"
    echo "apk add php84"
    echo

    apk add php84 \
        || fail "Gagal menginstall PHP."

else

    echo "PHP 8.4 sudah terinstall."

fi


if ! apk info -e php84-fpm >/dev/null 2>&1; then

    echo
    echo "PHP-FPM belum tersedia."
    echo "Command:"
    echo "apk add php84-fpm"
    echo

    apk add php84-fpm \
        || fail "Gagal menginstall PHP-FPM."

else

    echo "PHP-FPM sudah terinstall."

fi


if ! command -v curl >/dev/null 2>&1; then

    echo
    echo "curl belum tersedia."
    echo "Command:"
    echo "apk add curl"
    echo

    apk add curl \
        || fail "Gagal menginstall curl."

fi


echo
echo "Versi Nginx:"
nginx -v

echo
echo "Lokasi PHP-FPM:"
which php-fpm84

ok "Nginx dan PHP-FPM siap."

# ============================================================
# STEP 3 - SELESAI SAMPAI SINI
# ========================================================


# ============================================================
# STEP 4 - MEMBUAT HALAMAN WEB
# MULAI DARI SINI
# ========================================================

garis
echo "STEP 4/9 - Membuat halaman web Core K-03"
echo


mkdir -p /var/www/core


echo "Membuat:"
echo "/var/www/core/index.php"


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


echo
echo "Membuat:"
echo "/var/www/core/profil.php"


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


echo
echo "Isi direktori web:"
ls -l /var/www/core/


ok "Halaman web berhasil dibuat."

# ============================================================
# STEP 4 - SELESAI SAMPAI SINI
# ========================================================


# ============================================================
# STEP 5 - KONFIGURASI PHP-FPM
# MULAI DARI SINI
# ========================================================

garis
echo "STEP 5/9 - Mengatur PHP-FPM pada port 9000"
echo

echo "Command:"
echo "listen = 127.0.0.1:9000"
echo


sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' \
    /etc/php84/php-fpm.d/www.conf


echo "Hasil konfigurasi:"
grep -E '^[[:space:]]*listen[[:space:]]*=' \
    /etc/php84/php-fpm.d/www.conf


echo
echo "Validasi PHP-FPM:"
echo
echo "Command:"
echo "php-fpm84 -t"
echo


php-fpm84 -t \
    || fail "Konfigurasi PHP-FPM tidak valid."


ok "PHP-FPM berhasil dikonfigurasi."

# ============================================================
# STEP 5 - SELESAI SAMPAI SINI
# ========================================================


# ============================================================
# STEP 6 - KONFIGURASI NGINX
# MULAI DARI SINI
# ========================================================

garis
echo "STEP 6/9 - Membuat konfigurasi Nginx $NODE"
echo


mkdir -p /etc/nginx/http.d


cat > /etc/nginx/http.d/core.conf <<EOF
server {
    listen 80;

    server_name $NODE.$DOMAIN core.$DOMAIN;

    root /var/www/core;
    index index.php;

    rewrite ^/profil/?\$ /profil.php last;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass 127.0.0.1:9000;
    }
}
EOF


echo "Isi konfigurasi:"
echo "------------------------------------------------------------"
cat /etc/nginx/http.d/core.conf
echo "------------------------------------------------------------"


echo
echo "Validasi Nginx:"
echo
echo "Command:"
echo "nginx -t"
echo


nginx -t \
    || fail "Konfigurasi Nginx tidak valid."


ok "Konfigurasi Nginx valid."

# ============================================================
# STEP 6 - SELESAI SAMPAI SINI
# ========================================================


# ============================================================
# STEP 7 - MENJALANKAN SERVICE
# MULAI DARI SINI
# ========================================================

garis
echo "STEP 7/9 - Menjalankan PHP-FPM dan Nginx"
echo


echo "Menghentikan service lama jika ada..."


killall php-fpm84 2>/dev/null || true
killall nginx 2>/dev/null || true

# Jika BusyBox httpd kebetulan menggunakan port 80,
# hentikan supaya tidak bentrok dengan Nginx.
killall httpd 2>/dev/null || true


echo
echo "Menjalankan PHP-FPM..."
echo "Command:"
echo "php-fpm84"
echo

php-fpm84 \
    || fail "PHP-FPM gagal dijalankan."


echo
echo "Menjalankan Nginx..."
echo "Command:"
echo "nginx"
echo

nginx \
    || fail "Nginx gagal dijalankan."


sleep 1


echo
echo "Pengecekan port:"
echo "Command:"
echo "ss -ltnp | grep -E ':80|:9000'"
echo

ss -ltnp | grep -E ':80|:9000'


if ss -ltnp | grep -q '127.0.0.1:9000' && \
   ss -ltnp | grep -q ':80'; then

    ok "Nginx dan PHP-FPM aktif."

else

    fail "Port Nginx atau PHP-FPM belum aktif."

fi

# ============================================================
# STEP 7 - SELESAI SAMPAI SINI
# ========================================================


# ============================================================
# STEP 8 - TEST WEB SECARA LOKAL
# MULAI DARI SINI
# ========================================================

garis
echo "STEP 8/9 - Menguji web secara lokal"
echo


echo "Command:"
echo "curl -s -H 'Host: $NODE.$DOMAIN' http://127.0.0.1/"
echo

LOCAL_HOME="$(curl -s -H "Host: $NODE.$DOMAIN" http://127.0.0.1/)"

echo "$LOCAL_HOME"


echo
echo "Command:"
echo "curl -s -H 'Host: $NODE.$DOMAIN' http://127.0.0.1/profil"
echo

LOCAL_PROFILE="$(curl -s -H "Host: $NODE.$DOMAIN" http://127.0.0.1/profil)"

echo "$LOCAL_PROFILE"


if echo "$LOCAL_HOME" | grep -q "Halaman Beranda" && \
   echo "$LOCAL_HOME" | grep -q "Server: $NODE" && \
   echo "$LOCAL_PROFILE" | grep -q "Halaman Profil"; then

    ok "Web $NODE berhasil secara lokal."

else

    fail "Web lokal $NODE belum berjalan dengan benar."

fi

# ============================================================
# STEP 8 - SELESAI SAMPAI SINI
# ========================================================


# ============================================================
# STEP 9 - TEST MELALUI DNS
# MULAI DARI SINI
# ========================================================

garis
echo "STEP 9/9 - Menguji web melalui hostname DNS"
echo


cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF


echo "Isi resolver:"
cat /etc/resolv.conf


echo
echo "Command:"
echo "host $NODE.$DOMAIN"
echo

host "$NODE.$DOMAIN"


DNS_RESULT="$(host "$NODE.$DOMAIN" | awk '/has address/ {print $4}')"


echo
echo "IP yang diharapkan : $SERVER_IP"
echo "IP hasil DNS       : $DNS_RESULT"


if [ "$DNS_RESULT" != "$SERVER_IP" ]; then

    fail "DNS $NODE.$DOMAIN tidak sesuai."

fi


echo
echo "Menguji halaman Beranda:"
echo
echo "Command:"
echo "curl -s http://$NODE.$DOMAIN/"
echo

WEB_HOME="$(curl -s "http://$NODE.$DOMAIN/")"

echo "$WEB_HOME"


echo
echo "Menguji halaman Profil:"
echo
echo "Command:"
echo "curl -s http://$NODE.$DOMAIN/profil"
echo

WEB_PROFILE="$(curl -s "http://$NODE.$DOMAIN/profil")"

echo "$WEB_PROFILE"


if echo "$WEB_HOME" | grep -q "Halaman Beranda" && \
   echo "$WEB_HOME" | grep -q "Server: $NODE" && \
   echo "$WEB_PROFILE" | grep -q "Halaman Profil" && \
   echo "$WEB_PROFILE" | grep -q "Server: $NODE"; then

    ok "Web $NODE berhasil diakses melalui hostname."

else

    fail "Web melalui hostname belum sesuai."

fi


garis
echo "HASIL AKHIR SOAL 10"
echo "------------------------------------------------------------"
echo "Node      : $NODE"
echo "IP        : $SERVER_IP"
echo "Interface : $INTERFACE"
echo "Hostname  : $NODE.$DOMAIN"
echo
echo "Beranda   : http://$NODE.$DOMAIN/"
echo "Profil    : http://$NODE.$DOMAIN/profil"
echo
echo "[OK] Jaringan berhasil."
echo "[OK] Route DNS berhasil."
echo "[OK] Nginx aktif."
echo "[OK] PHP-FPM aktif."
echo "[OK] Beranda berhasil."
echo "[OK] Halaman Profil berhasil."
echo "[OK] Akses melalui hostname berhasil."
garis

echo
echo "SOAL 10 - $NODE SELESAI"
echo

# ============================================================
# STEP 9 - SELESAI SAMPAI SINI
# ============================================================
