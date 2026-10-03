#!/bin/sh

# ============================================================
# K-03 - SOAL 6
# ============================================================

NODE="$(hostname)"

DOMAIN="k-03.com"

MASTER_IP="10.65.2.3"
SLAVE_IP="10.65.2.2"

EXPECTED_SERIAL="2026092902"


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
echo " K-03 - SOAL 6"
echo " Node terdeteksi: $NODE"
echo "============================================================"


# ============================================================
# CEK NODE
# ============================================================

if [ "$NODE" != "tedd" ]; then

    garis
    echo "[GAGAL] Script Soal 6 dijalankan pada node yang salah."
    echo
    echo "Node sekarang : $NODE"
    echo "Node yang digunakan untuk Soal 6 : tedd"
    garis

    exit 1
fi


# ============================================================
# STEP 1 - CEK TOOL DNS
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 1/6 - Mengecek command DNS yang dibutuhkan"
echo

echo "Command yang dicek:"
echo "dig"
echo

if command -v dig >/dev/null 2>&1; then

    ok "Command dig tersedia."

else

    echo "dig belum tersedia."
    echo "Menginstall bind-tools..."
    echo
    echo "Command:"
    echo "apk add bind-tools"
    echo

    apk add bind-tools \
        || fail "Gagal menginstall bind-tools."

    ok "bind-tools berhasil diinstall."
fi

# ============================================================
# STEP 1 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 2 - CEK KONEKSI TEDD KE PRAB
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 2/6 - Mengecek koneksi TEDD ke DNS Master PRAB"
echo

echo "Command:"
echo "ping -c 4 $MASTER_IP"
echo

if ping -c 4 "$MASTER_IP"; then

    ok "TEDD dapat terhubung ke PRAB."

else

    fail "TEDD tidak dapat terhubung ke PRAB $MASTER_IP."
fi

# ============================================================
# STEP 2 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 3 - CEK SOA PRAB DAN TEDD
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 3/6 - Mengecek SOA DNS Master dan Slave"
echo

echo "Command PRAB:"
echo "dig @$MASTER_IP $DOMAIN SOA +short"
echo

MASTER_SOA="$(dig @"$MASTER_IP" "$DOMAIN" SOA +short)"

echo "$MASTER_SOA"


echo
echo "Command TEDD:"
echo "dig @$SLAVE_IP $DOMAIN SOA +short"
echo

SLAVE_SOA="$(dig @"$SLAVE_IP" "$DOMAIN" SOA +short)"

echo "$SLAVE_SOA"


MASTER_SERIAL="$(echo "$MASTER_SOA" | awk '{print $3}')"
SLAVE_SERIAL="$(echo "$SLAVE_SOA" | awk '{print $3}')"


echo
echo "------------------------------------------------------------"
echo "Serial PRAB : $MASTER_SERIAL"
echo "Serial TEDD : $SLAVE_SERIAL"
echo "------------------------------------------------------------"


if [ "$MASTER_SERIAL" = "$SLAVE_SERIAL" ]; then

    ok "Serial PRAB dan TEDD sama."

else

    fail "Serial PRAB dan TEDD berbeda."
fi

# ============================================================
# STEP 3 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 4 - CEK SERIAL YANG DIHARAPKAN
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 4/6 - Mengecek versi zone"
echo

echo "Serial yang diharapkan : $EXPECTED_SERIAL"
echo "Serial pada PRAB        : $MASTER_SERIAL"
echo "Serial pada TEDD        : $SLAVE_SERIAL"


if [ "$MASTER_SERIAL" = "$EXPECTED_SERIAL" ] && \
   [ "$SLAVE_SERIAL" = "$EXPECTED_SERIAL" ]; then

    ok "Kedua DNS menggunakan zone versi $EXPECTED_SERIAL."

else

    fail "Serial DNS belum sesuai dengan hasil Soal 5."
fi

# ============================================================
# STEP 4 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 5 - CEK RECORD PADA DNS SLAVE
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 5/6 - Mengecek record hasil sinkronisasi pada TEDD"
echo


echo "Command:"
echo "dig @$SLAVE_IP molly.$DOMAIN A +short"
echo

MOLLY_RESULT="$(dig @"$SLAVE_IP" "molly.$DOMAIN" A +short)"

echo "$MOLLY_RESULT"


echo
echo "Command:"
echo "dig @$SLAVE_IP beta.$DOMAIN A +short"
echo

BETA_RESULT="$(dig @"$SLAVE_IP" "beta.$DOMAIN" A +short)"

echo "$BETA_RESULT"


echo
echo "Hasil yang diharapkan:"
echo "molly.$DOMAIN -> 10.65.3.2"
echo "beta.$DOMAIN  -> 10.65.6.3"


if [ "$MOLLY_RESULT" = "10.65.3.2" ] && \
   [ "$BETA_RESULT" = "10.65.6.3" ]; then

    ok "Record terbaru sudah tersedia pada DNS Slave."

else

    fail "Record pada DNS Slave belum sesuai."
fi

# ============================================================
# STEP 5 - SELESAI SAMPAI SINI
# ============================================================


# ============================================================
# STEP 6 - TEST ZONE TRANSFER AXFR
# MULAI DARI SINI
# ============================================================

garis
echo "STEP 6/6 - Menguji Zone Transfer dari PRAB ke TEDD"
echo

echo "Command:"
echo "dig @$MASTER_IP $DOMAIN AXFR"
echo


AXFR_RESULT="$(dig @"$MASTER_IP" "$DOMAIN" AXFR)"

echo "$AXFR_RESULT"


echo
echo "------------------------------------------------------------"
echo "Mengecek apakah zone transfer berhasil..."
echo "------------------------------------------------------------"


if echo "$AXFR_RESULT" | grep -q "XFR size"; then

    ok "Zone Transfer AXFR berhasil."

else

    fail "Zone Transfer AXFR gagal."
fi


garis
echo "HASIL AKHIR SOAL 6"
echo "------------------------------------------------------------"
echo "DNS Master : PRAB ($MASTER_IP)"
echo "DNS Slave  : TEDD ($SLAVE_IP)"
echo "Serial     : $MASTER_SERIAL"
echo
echo "[OK] DNS Master dan Slave telah sinkron."
echo "[OK] Record pada TEDD berhasil diverifikasi."
echo "[OK] Zone Transfer AXFR berhasil."
garis

echo
echo "SOAL 6 SELESAI"
echo
