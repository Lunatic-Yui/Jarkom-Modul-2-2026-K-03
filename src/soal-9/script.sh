#!/bin/sh

# ============================================================
# K-03 - SOAL 9
# ============================================================

NODE="$(hostname)"

MASTER_IP="10.65.2.3"
SLAVE_IP="10.65.2.2"
EXTERNAL_DNS="192.168.122.1"

DOMAIN="k-03.com"


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
echo " K-03 - SOAL 9"
echo " Node terdeteksi: $NODE"
echo "============================================================"


# ============================================================
# CEK NODE
# ============================================================

if [ "$NODE" != "obladi" ] && [ "$NODE" != "desmond" ]; then

    garis
    echo "[GAGAL] Script Soal 9 dijalankan pada node yang salah."
    echo
    echo "Node sekarang : $NODE"
    echo
    echo "Script ini digunakan pada:"
    echo "  - obladi"
    echo "  - desmond"
    garis

    exit 1
fi


# ============================================================
# STEP 1 - CEK KONFIGURASI JARINGAN
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 1/8 - Mengecek konfigurasi jaringan $NODE"
echo

echo "Command:"
echo "ip addr show eth0"
echo

ip addr show eth0

echo
echo "Command:"
echo "ip route"
echo

ip route

# ============================================================
# STEP 1 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 2 - TAMBAHKAN ROUTE MENUJU DNS
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 2/8 - Memastikan route langsung menuju subnet DNS"
echo

echo "Route yang dibutuhkan:"
echo "10.65.2.0/24 dev eth0"
echo

if ip route show | grep -q '^10.65.2.0/24 dev eth0'; then

    echo "Route sudah tersedia."

else

    echo "Route belum tersedia."
    echo
    echo "Command:"
    echo "ip route add 10.65.2.0/24 dev eth0"
    echo

    ip route add 10.65.2.0/24 dev eth0 \
        || fail "Gagal menambahkan route ke subnet DNS."

fi


echo
echo "Routing table setelah konfigurasi:"
ip route


echo
echo "Menguji koneksi ke PRAB..."
echo
echo "Command:"
echo "ping -c 4 $MASTER_IP"
echo

if ping -c 4 "$MASTER_IP"; then

    ok "$NODE dapat menghubungi PRAB tanpa ICMP Redirect."

else

    fail "$NODE tidak dapat menghubungi PRAB."

fi

# ============================================================
# STEP 2 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 3 - MEMBERSIHKAN PORT 80
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 3/8 - Memastikan port 80 siap digunakan Apache"
echo

echo "Service pada port 80 sebelum dibersihkan:"
ss -ltnp | grep ':80' || echo "Port 80 saat ini kosong."


echo
echo "Menghentikan proses httpd lama jika ada..."
echo
echo "Command:"
echo "killall httpd 2>/dev/null || true"
echo

killall httpd 2>/dev/null || true

sleep 1


echo
echo "Pengecekan ulang port 80:"

if ss -ltnp | grep -q ':80'; then

    echo
    ss -ltnp | grep ':80'
    fail "Port 80 masih digunakan proses lain."

else

    ok "Port 80 sudah kosong dan siap digunakan."

fi

# ============================================================
# STEP 3 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 4 - INSTALL APACHE
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 4/8 - Memastikan Apache tersedia"
echo

echo "Menggunakan DNS eksternal sementara untuk instalasi paket."

cat > /etc/resolv.conf <<EOF
nameserver $EXTERNAL_DNS
EOF


if apk info -e apache2 >/dev/null 2>&1; then

    echo "Apache sudah terinstall."

else

    echo "Apache belum tersedia."
    echo
    echo "Command:"
    echo "apk add apache2"
    echo

    apk add apache2 \
        || fail "Gagal menginstall Apache."

fi


echo
echo "Versi Apache:"
httpd -v

ok "Apache siap digunakan."

# ============================================================
# STEP 4 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 5 - MEMBUAT DIREKTORI ARSIP
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 5/8 - Membuat direktori /arsip/"
echo

echo "Command:"
echo "mkdir -p /var/www/localhost/htdocs/arsip"
echo

mkdir -p /var/www/localhost/htdocs/arsip


echo
echo "Membuat file arsip pada $NODE..."


if [ "$NODE" = "obladi" ]; then

    echo "Arsip statis dari Obladi" \
        > /var/www/localhost/htdocs/arsip/obladi.txt

else

    echo "Arsip statis dari Desmond" \
        > /var/www/localhost/htdocs/arsip/desmond.txt

fi


echo "Dokumen Vault K-03" \
    > /var/www/localhost/htdocs/arsip/dokumen-vault.txt

echo "Data jaringan area Vault" \
    > /var/www/localhost/htdocs/arsip/network-info.txt


echo
echo "Isi direktori /arsip/:"
echo

ls -l /var/www/localhost/htdocs/arsip/


ok "Direktori arsip berhasil dibuat."

# ============================================================
# STEP 5 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 6 - KONFIGURASI APACHE
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 6/8 - Membuat konfigurasi Apache"
echo


cat > /etc/apache2/conf.d/vault.conf <<EOF
ServerName $NODE.$DOMAIN

<Directory "/var/www/localhost/htdocs/arsip">
    Options +Indexes
    AllowOverride None
    Require all granted
</Directory>
EOF


echo "Isi konfigurasi:"
echo "------------------------------------------------------------"
cat /etc/apache2/conf.d/vault.conf
echo "------------------------------------------------------------"


echo
echo "Validasi konfigurasi Apache..."
echo
echo "Command:"
echo "httpd -t"
echo

httpd -t \
    || fail "Konfigurasi Apache tidak valid."


ok "Konfigurasi Apache valid."

# ============================================================
# STEP 6 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 7 - MENJALANKAN APACHE
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 7/8 - Menjalankan Apache"
echo

echo "Menghentikan instance httpd lama jika ada..."
killall httpd 2>/dev/null || true

echo
echo "Menjalankan:"
echo "httpd"
echo

httpd \
    || fail "Apache gagal dijalankan."

sleep 1


echo
echo "Pengecekan port 80:"
echo

ss -ltnp | grep ':80'


if ss -ltnp | grep -q ':80'; then

    ok "Apache aktif pada port 80."

else

    fail "Apache tidak ditemukan pada port 80."

fi


echo
echo "Tes directory listing secara lokal:"
echo
echo "Command:"
echo "wget -qO- http://127.0.0.1/arsip/"
echo

LOCAL_RESULT="$(wget -qO- http://127.0.0.1/arsip/)"

echo "$LOCAL_RESULT"


if echo "$LOCAL_RESULT" | grep -q "Index of /arsip"; then

    ok "Directory listing /arsip/ berhasil secara lokal."

else

    fail "Directory listing lokal tidak berhasil."

fi

# ============================================================
# STEP 7 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 8 - DNS INTERNAL DAN VERIFIKASI AKHIR
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 8/8 - Menguji akses melalui hostname"
echo


cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF


echo "Resolver yang digunakan:"
cat /etc/resolv.conf


echo
echo "Mengecek hostname DNS:"
echo
echo "Command:"
echo "host $NODE.$DOMAIN"
echo

host "$NODE.$DOMAIN"


EXPECTED_IP=""

if [ "$NODE" = "obladi" ]; then
    EXPECTED_IP="10.65.3.5"
fi

if [ "$NODE" = "desmond" ]; then
    EXPECTED_IP="10.65.3.4"
fi


DNS_RESULT="$(host "$NODE.$DOMAIN" | awk '/has address/ {print $4}')"


echo
echo "IP yang diharapkan : $EXPECTED_IP"
echo "IP hasil DNS       : $DNS_RESULT"


if [ "$DNS_RESULT" != "$EXPECTED_IP" ]; then

    fail "DNS $NODE.$DOMAIN tidak sesuai."

fi


echo
echo "Menguji directory listing melalui hostname:"
echo
echo "Command:"
echo "wget -qO- http://$NODE.$DOMAIN/arsip/"
echo


WEB_RESULT="$(wget -qO- "http://$NODE.$DOMAIN/arsip/")"

echo "$WEB_RESULT"


if echo "$WEB_RESULT" | grep -q "Index of /arsip"; then

    ok "Directory listing dapat diakses melalui $NODE.$DOMAIN."

else

    fail "Directory listing melalui hostname gagal."

fi


garis
echo "HASIL AKHIR SOAL 9"
echo "------------------------------------------------------------"
echo "Node       : $NODE"
echo "IP         : $EXPECTED_IP"
echo "Hostname   : $NODE.$DOMAIN"
echo "Web        : http://$NODE.$DOMAIN/arsip/"
echo
echo "[OK] Route menuju DNS tersedia."
echo "[OK] Apache aktif pada port 80."
echo "[OK] Directory listing /arsip/ aktif."
echo "[OK] Akses melalui hostname berhasil."
garis

echo
echo "SOAL 9 - $NODE SELESAI"
echo

# ============================================================
# STEP 8 - SELESAI SAMPAI SINI
# ============================================================
