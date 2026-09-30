#!/bin/sh

# ============================================================
# SOAL 9
# Web Statis Area Vault menggunakan Apache
#
# OBLADI  : 10.65.3.5
# DESMOND : 10.65.3.4
#
# Target:
# http://obladi.k-03.com/arsip/
# http://desmond.k-03.com/arsip/
# ============================================================


# ============================================================
# [OBLADI]
# Konfigurasi resolver
# ============================================================

cat > /etc/resolv.conf <<'EOF'
nameserver 10.65.2.3
nameserver 10.65.2.2
nameserver 192.168.122.1
EOF


# ============================================================
# [OBLADI]
# Install Apache
# ============================================================

apk update
apk add apache2


# ============================================================
# [OBLADI]
# Membuat direktori dan file arsip
# ============================================================

mkdir -p /var/www/localhost/htdocs/arsip

echo "Arsip statis dari Obladi" > /var/www/localhost/htdocs/arsip/obladi.txt
echo "Dokumen Vault K-03" > /var/www/localhost/htdocs/arsip/dokumen-vault.txt
echo "Data jaringan area Vault" > /var/www/localhost/htdocs/arsip/network-info.txt


# ============================================================
# [OBLADI]
# Mengaktifkan Directory Listing
# ============================================================

cat > /etc/apache2/conf.d/vault.conf <<'CONF'
ServerName obladi.k-03.com

<Directory "/var/www/localhost/htdocs/arsip">
    Options +Indexes
    AllowOverride None
    Require all granted
</Directory>
CONF

httpd -t

killall httpd 2>/dev/null || true
httpd


# ============================================================
# [OBLADI]
# Verifikasi lokal
# ============================================================

# wget -qO- http://127.0.0.1/arsip/
# curl http://127.0.0.1/arsip/


# ============================================================
# [DESMOND]
# Konfigurasi resolver
# ============================================================

cat > /etc/resolv.conf <<'EOF'
nameserver 10.65.2.3
nameserver 10.65.2.2
nameserver 192.168.122.1
EOF


# ============================================================
# [DESMOND]
# Install Apache
# ============================================================

apk update
apk add apache2


# ============================================================
# [DESMOND]
# Membuat direktori dan file arsip
# ============================================================

mkdir -p /var/www/localhost/htdocs/arsip

echo "Arsip statis dari Desmond" > /var/www/localhost/htdocs/arsip/desmond.txt
echo "Dokumen Vault K-03" > /var/www/localhost/htdocs/arsip/dokumen-vault.txt
echo "Data jaringan area Vault" > /var/www/localhost/htdocs/arsip/network-info.txt


# ============================================================
# [DESMOND]
# Mengaktifkan Directory Listing
# ============================================================

cat > /etc/apache2/conf.d/vault.conf <<'CONF'
ServerName desmond.k-03.com

<Directory "/var/www/localhost/htdocs/arsip">
    Options +Indexes
    AllowOverride None
    Require all granted
</Directory>
CONF

httpd -t

killall httpd 2>/dev/null || true
httpd


# ============================================================
# [DESMOND]
# Verifikasi lokal
# ============================================================

# wget -qO- http://127.0.0.1/arsip/
# curl http://127.0.0.1/arsip/


# ============================================================
# [CLIENT - contoh: ALPHA]
# Verifikasi melalui hostname
# ============================================================

# curl http://obladi.k-03.com/arsip/
# curl http://desmond.k-03.com/arsip/


# ============================================================
# HASIL YANG DIHARAPKAN
# ============================================================

# Obladi:
# Index of /arsip
# - dokumen-vault.txt
# - network-info.txt
# - obladi.txt
#
# Desmond:
# Index of /arsip
# - desmond.txt
# - dokumen-vault.txt
# - network-info.txt
#
# Pengujian harus dilakukan menggunakan hostname,
# bukan alamat IP secara langsung.
