#!/bin/sh

# ============================================================
# SOAL 5
# Konfigurasi Hostname dan A Record Seluruh Entitas
# Domain : k-03.com
#
# Asumsi:
# - Konfigurasi DNS Master-Slave pada Soal 4 sudah berjalan
# - PRAB : 10.65.2.3
# - TEDD : 10.65.2.2
# ============================================================


# ============================================================
# [ROOTKIT]
# Mengubah hostname router menjadi "rootkit"
# ============================================================

hostname rootkit
echo "rootkit" > /etc/hostname

# Verifikasi:
# hostname


# ============================================================
# [PRAB]
# Memperbarui forward zone k-03.com
# Serial SOA dinaikkan dari 2026092901 menjadi 2026092902
# ============================================================

cat > /var/bind/db.k-03.com <<'ZONE'
$TTL 86400

@   IN  SOA prab.k-03.com. root.k-03.com. (
        2026092902
        3600
        1800
        604800
        86400
)

@       IN  NS      prab.k-03.com.
@       IN  NS      tedd.k-03.com.

@       IN  A       10.65.5.2

prab    IN  A       10.65.2.3
tedd    IN  A       10.65.2.2

rootkit IN  A       10.65.1.1

alpha   IN  A       10.65.6.2
beta    IN  A       10.65.6.3
gamma   IN  A       10.65.6.4

delta   IN  A       10.65.7.2
epsilon IN  A       10.65.7.3

abbey   IN  A       10.65.4.2
penny   IN  A       10.65.5.2

obladi  IN  A       10.65.3.5
desmond IN  A       10.65.3.4
oblada  IN  A       10.65.3.3
molly   IN  A       10.65.3.2
ZONE


# ============================================================
# [PRAB]
# Validasi dan reload DNS Master
# ============================================================

named-checkzone k-03.com /var/bind/db.k-03.com

killall named 2>/dev/null || true
named -c /etc/bind/named.conf


# ============================================================
# [VERIFIKASI PRAB]
# Memastikan A record telah terbaca oleh DNS Master
# ============================================================

# dig @10.65.2.3 alpha.k-03.com A +short
# dig @10.65.2.3 beta.k-03.com A +short
# dig @10.65.2.3 abbey.k-03.com A +short
# dig @10.65.2.3 penny.k-03.com A +short
# dig @10.65.2.3 oblada.k-03.com A +short
# dig @10.65.2.3 molly.k-03.com A +short
# dig @10.65.2.3 rootkit.k-03.com A +short


# ============================================================
# [TEDD]
# Verifikasi bahwa perubahan zone sudah tersinkronisasi
# ============================================================

# dig @10.65.2.2 k-03.com SOA +short
# dig @10.65.2.2 alpha.k-03.com A +short
# dig @10.65.2.2 molly.k-03.com A +short


# ============================================================
# [CLIENT - contoh: ALPHA]
# Verifikasi resolusi hostname seluruh entitas
# ============================================================

# host alpha.k-03.com
# host beta.k-03.com
# host abbey.k-03.com
# host penny.k-03.com
# host oblada.k-03.com
# host molly.k-03.com
