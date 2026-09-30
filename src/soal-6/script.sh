#!/bin/sh

# ============================================================
# SOAL 6
# Verifikasi Zone Transfer PRAB -> TEDD
#
# PRAB : 10.65.2.3
# TEDD : 10.65.2.2
# Domain: k-03.com
#
# Asumsi:
# - Soal 4 dan 5 sudah selesai
# - Serial terbaru zone adalah 2026092902
# ============================================================


# ============================================================
# [TEDD]
# Membandingkan serial SOA pada PRAB dan TEDD
# ============================================================

echo "=== SOA PRAB ==="
dig @10.65.2.3 k-03.com SOA +short

echo "=== SOA TEDD ==="
dig @10.65.2.2 k-03.com SOA +short


# ============================================================
# [TEDD]
# Memastikan record terbaru sudah tersedia pada DNS Slave
# ============================================================

echo "=== RECORD TERBARU DI TEDD ==="
dig @10.65.2.2 molly.k-03.com A +short
dig @10.65.2.2 beta.k-03.com A +short


# ============================================================
# [TEDD]
# Verifikasi AXFR dari DNS Master PRAB
# ============================================================

echo "=== AXFR PRAB -> TEDD ==="
dig @10.65.2.3 k-03.com AXFR


# ============================================================
# HASIL YANG DIHARAPKAN
# ============================================================

# Serial SOA PRAB dan TEDD harus sama:
# 2026092902
#
# Record terbaru:
# molly.k-03.com -> 10.65.3.2
# beta.k-03.com  -> 10.65.6.3
#
# Pada hasil AXFR harus muncul seluruh record zone
# dan bagian akhir menampilkan "XFR size".
