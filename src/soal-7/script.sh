#!/bin/sh

# ============================================================
# SOAL 7
# Konfigurasi Record Vault, Core, WWW, dan Static
#
# Domain : k-03.com
# PRAB   : 10.65.2.3
# TEDD   : 10.65.2.2
#
# Asumsi:
# - Soal 4, 5, dan 6 sudah selesai
# - Serial sebelumnya: 2026092902
# ============================================================


# ============================================================
# [PRAB]
# Naikkan serial SOA
# ============================================================

sed -i 's/2026092902/2026092903/' /var/bind/db.k-03.com


# ============================================================
# [PRAB]
# Tambahkan record Vault, Core, WWW, dan Static
# ============================================================

cat >> /var/bind/db.k-03.com <<'EOF'

vault   IN  A       10.65.3.5
vault   IN  A       10.65.3.4

core    IN  A       10.65.3.3
core    IN  A       10.65.3.2

www     IN  CNAME   penny.k-03.com.
static  IN  CNAME   abbey.k-03.com.
EOF


# ============================================================
# [PRAB]
# Validasi dan reload DNS Master
# ============================================================

named-checkzone k-03.com /var/bind/db.k-03.com

killall named 2>/dev/null || true
named -c /etc/bind/named.conf


# ============================================================
# [PRAB]
# Verifikasi record baru
# ============================================================

echo "=== VAULT ==="
dig @10.65.2.3 vault.k-03.com A +short

echo "=== CORE ==="
dig @10.65.2.3 core.k-03.com A +short

echo "=== WWW ==="
dig @10.65.2.3 www.k-03.com CNAME +short

echo "=== STATIC ==="
dig @10.65.2.3 static.k-03.com CNAME +short


# ============================================================
# [TEDD]
# Verifikasi sinkronisasi zone
# ============================================================

# dig @10.65.2.2 k-03.com SOA +short
# dig @10.65.2.2 vault.k-03.com A +short
# dig @10.65.2.2 core.k-03.com A +short
# dig @10.65.2.2 www.k-03.com CNAME +short
# dig @10.65.2.2 static.k-03.com CNAME +short


# ============================================================
# [CLIENT - ALPHA]
# Verifikasi resolusi dari client pertama
# ============================================================

# host vault.k-03.com
# host core.k-03.com
# host www.k-03.com
# host static.k-03.com


# ============================================================
# [CLIENT - DELTA]
# Verifikasi resolusi dari client kedua
# ============================================================

# host vault.k-03.com
# host core.k-03.com
# host www.k-03.com
# host static.k-03.com


# ============================================================
# HASIL YANG DIHARAPKAN
# ============================================================

# vault.k-03.com:
# 10.65.3.5 -> Obladi
# 10.65.3.4 -> Desmond
#
# core.k-03.com:
# 10.65.3.3 -> Oblada
# 10.65.3.2 -> Molly
#
# www.k-03.com:
# CNAME -> penny.k-03.com
#
# static.k-03.com:
# CNAME -> abbey.k-03.com
#
# Serial SOA terbaru:
# 2026092903
