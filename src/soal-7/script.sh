#!/bin/sh

# ============================================================
# K-03 - SOAL 7
# ============================================================

NODE="$(hostname)"

DOMAIN="k-03.com"

MASTER_IP="10.65.2.3"
SLAVE_IP="10.65.2.2"
EXTERNAL_DNS="192.168.122.1"

SERIAL="2026092903"


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
echo " K-03 - SOAL 7"
echo " Node terdeteksi: $NODE"
echo "============================================================"


# ============================================================
# NODE PRAB
# ============================================================

if [ "$NODE" = "prab" ]; then

    # ========================================================
    # STEP 1 - CEK DNS MASTER
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 1/6 - Mengecek DNS Master PRAB"
    echo
    echo "Command:"
    echo "dig @$MASTER_IP $DOMAIN SOA +short"
    echo

    if ! command -v dig >/dev/null 2>&1; then

        cat > /etc/resolv.conf <<EOF
nameserver $EXTERNAL_DNS
EOF

        echo "bind-tools belum tersedia."
        echo "Menjalankan:"
        echo "apk add bind bind-tools"
        echo

        apk add bind bind-tools \
            || fail "Gagal menginstall BIND."
    fi

    dig @"$MASTER_IP" "$DOMAIN" SOA +short 2>/dev/null || true

    ok "Pengecekan awal selesai."

    # ========================================================
    # STEP 1 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 2 - MEMASTIKAN KONFIGURASI MASTER
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/6 - Memastikan konfigurasi DNS Master"

    mkdir -p /etc/bind
    mkdir -p /var/bind

    cat > /etc/bind/named.conf <<EOF
options {
    directory "/var/bind";
    listen-on { any; };
    listen-on-v6 { none; };
    allow-query { any; };
    recursion yes;
    dnssec-validation no;
    forwarders { $EXTERNAL_DNS; };
};

zone "$DOMAIN" {
    type master;
    file "db.k-03.com";
    notify yes;
    also-notify { $SLAVE_IP; };
    allow-transfer { $SLAVE_IP; };
};
EOF

    echo
    echo "Isi /etc/bind/named.conf:"
    echo "------------------------------------------------------------"
    cat /etc/bind/named.conf
    echo "------------------------------------------------------------"

    ok "Konfigurasi DNS Master siap."

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - UPDATE ZONE SOAL 7
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/6 - Menambahkan record vault, core, www, dan static"
    echo
    echo "Serial baru: $SERIAL"

    cat > /var/bind/db.k-03.com <<EOF
\$TTL 86400

@   IN  SOA prab.k-03.com. root.k-03.com. (
        $SERIAL
        3600
        1800
        604800
        86400
)

@       IN  NS      prab.k-03.com.
@       IN  NS      tedd.k-03.com.

@       IN  A       10.65.5.2

prab        IN  A       10.65.2.3
tedd        IN  A       10.65.2.2

rootkit     IN  A       10.65.1.1

alpha       IN  A       10.65.6.2
beta        IN  A       10.65.6.3
gamma       IN  A       10.65.6.4

delta       IN  A       10.65.7.2
epsilon     IN  A       10.65.7.3

abbey       IN  A       10.65.4.2
penny       IN  A       10.65.5.2

obladi      IN  A       10.65.3.5
desmond     IN  A       10.65.3.4

oblada      IN  A       10.65.3.3
molly       IN  A       10.65.3.2

vault       IN  A       10.65.3.5
vault       IN  A       10.65.3.4

core        IN  A       10.65.3.3
core        IN  A       10.65.3.2

www         IN  CNAME   penny.k-03.com.
static      IN  CNAME   abbey.k-03.com.
EOF

    echo
    echo "Record baru Soal 7:"
    echo "------------------------------------------------------------"
    grep -E '^(vault|core|www|static)' /var/bind/db.k-03.com
    echo "------------------------------------------------------------"

    ok "Record Soal 7 berhasil ditambahkan."

    # ========================================================
    # STEP 3 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 4 - VALIDASI ZONE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 4/6 - Memvalidasi konfigurasi DNS"
    echo

    echo "Command:"
    echo "named-checkconf"
    echo

    named-checkconf \
        || fail "named.conf tidak valid."

    echo
    echo "Command:"
    echo "named-checkzone $DOMAIN /var/bind/db.k-03.com"
    echo

    named-checkzone "$DOMAIN" /var/bind/db.k-03.com \
        || fail "Zone $DOMAIN tidak valid."

    ok "Konfigurasi DNS valid."

    # ========================================================
    # STEP 4 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 5 - RESTART DNS MASTER
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 5/6 - Restart DNS Master PRAB"
    echo

    echo "Menghentikan named lama jika aktif..."
    killall named 2>/dev/null || true

    echo
    echo "Menjalankan:"
    echo "named -c /etc/bind/named.conf"
    echo

    named -c /etc/bind/named.conf \
        || fail "BIND gagal dijalankan."

    sleep 2

    if ss -lunp | grep -q ':53'; then
        ok "DNS Master aktif pada port 53."
    else
        fail "DNS Master tidak aktif."
    fi

    # ========================================================
    # STEP 5 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 6 - VERIFIKASI RECORD
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 6/6 - Verifikasi record Soal 7"

    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF

    echo
    echo "Cek SOA:"
    dig @"$MASTER_IP" "$DOMAIN" SOA +short

    CURRENT_SERIAL="$(dig @"$MASTER_IP" "$DOMAIN" SOA +short | awk '{print $3}')"

    echo
    echo "Serial yang diharapkan : $SERIAL"
    echo "Serial PRAB            : $CURRENT_SERIAL"

    if [ "$CURRENT_SERIAL" != "$SERIAL" ]; then
        fail "Serial PRAB tidak sesuai."
    fi

    echo
    echo "------------------------------------------------------------"
    echo "Record vault:"
    echo "------------------------------------------------------------"
    dig @"$MASTER_IP" "vault.$DOMAIN" A +short

    echo
    echo "------------------------------------------------------------"
    echo "Record core:"
    echo "------------------------------------------------------------"
    dig @"$MASTER_IP" "core.$DOMAIN" A +short

    echo
    echo "------------------------------------------------------------"
    echo "CNAME www:"
    echo "------------------------------------------------------------"
    dig @"$MASTER_IP" "www.$DOMAIN" CNAME +short

    echo
    echo "------------------------------------------------------------"
    echo "CNAME static:"
    echo "------------------------------------------------------------"
    dig @"$MASTER_IP" "static.$DOMAIN" CNAME +short


    WWW_RESULT="$(dig @"$MASTER_IP" "www.$DOMAIN" CNAME +short)"
    STATIC_RESULT="$(dig @"$MASTER_IP" "static.$DOMAIN" CNAME +short)"


    if [ "$WWW_RESULT" = "penny.k-03.com." ] && \
       [ "$STATIC_RESULT" = "abbey.k-03.com." ]; then

        ok "Record Soal 7 pada PRAB berhasil."

    else

        fail "CNAME www atau static belum sesuai."
    fi


    garis
    echo "SOAL 7 - KONFIGURASI PRAB SELESAI"
    garis

    exit 0

    # ========================================================
    # STEP 6 - SELESAI SAMPAI SINI
    # ========================================================
fi


# ============================================================
# NODE TEDD
# ============================================================

if [ "$NODE" = "tedd" ]; then

    # ========================================================
    # STEP 1 - CEK PRAB
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 1/4 - Mengecek koneksi TEDD ke PRAB"
    echo
    echo "Command:"
    echo "ping -c 4 $MASTER_IP"
    echo

    if ping -c 4 "$MASTER_IP"; then
        ok "TEDD dapat menghubungi PRAB."
    else
        fail "TEDD tidak dapat menghubungi PRAB."
    fi

    # ========================================================
    # STEP 1 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 2 - MEMASTIKAN DNS SLAVE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/4 - Memastikan konfigurasi DNS Slave"

    if ! command -v dig >/dev/null 2>&1; then

        cat > /etc/resolv.conf <<EOF
nameserver $EXTERNAL_DNS
EOF

        apk add bind bind-tools \
            || fail "Gagal menginstall BIND."
    fi

    mkdir -p /etc/bind
    mkdir -p /var/bind/slaves

    chown -R named:named /var/bind/slaves 2>/dev/null || true

    cat > /etc/bind/named.conf <<EOF
options {
    directory "/var/bind";
    listen-on { any; };
    listen-on-v6 { none; };
    allow-query { any; };
    recursion yes;
    dnssec-validation no;
    forwarders { $EXTERNAL_DNS; };
};

zone "$DOMAIN" {
    type slave;
    masters { $MASTER_IP; };
    file "slaves/db.k-03.com";
};
EOF

    named-checkconf \
        || fail "Konfigurasi DNS Slave tidak valid."

    ok "Konfigurasi TEDD valid."

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - SINKRONISASI
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/4 - Sinkronisasi zone terbaru dari PRAB"

    echo
    echo "Menghapus salinan zone lama..."
    rm -f /var/bind/slaves/db.k-03.com

    echo
    echo "Restart DNS Slave..."

    killall named 2>/dev/null || true

    named -c /etc/bind/named.conf \
        || fail "DNS Slave gagal dijalankan."

    echo
    echo "Menunggu zone transfer..."
    sleep 3


    MASTER_SERIAL="$(dig @"$MASTER_IP" "$DOMAIN" SOA +short | awk '{print $3}')"
    SLAVE_SERIAL="$(dig @"$SLAVE_IP" "$DOMAIN" SOA +short | awk '{print $3}')"


    echo
    echo "Serial PRAB : $MASTER_SERIAL"
    echo "Serial TEDD : $SLAVE_SERIAL"


    if [ "$MASTER_SERIAL" = "$SERIAL" ] && \
       [ "$SLAVE_SERIAL" = "$SERIAL" ]; then

        ok "TEDD sudah sinkron dengan PRAB."

    else

        fail "Serial PRAB dan TEDD belum sinkron."
    fi

    # ========================================================
    # STEP 3 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 4 - VERIFIKASI RECORD
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 4/4 - Mengecek record Soal 7 pada TEDD"

    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF


    echo
    echo "Record vault:"
    dig @"$SLAVE_IP" "vault.$DOMAIN" A +short

    echo
    echo "Record core:"
    dig @"$SLAVE_IP" "core.$DOMAIN" A +short

    echo
    echo "CNAME www:"
    dig @"$SLAVE_IP" "www.$DOMAIN" CNAME +short

    echo
    echo "CNAME static:"
    dig @"$SLAVE_IP" "static.$DOMAIN" CNAME +short


    WWW_RESULT="$(dig @"$SLAVE_IP" "www.$DOMAIN" CNAME +short)"
    STATIC_RESULT="$(dig @"$SLAVE_IP" "static.$DOMAIN" CNAME +short)"


    if [ "$WWW_RESULT" = "penny.k-03.com." ] && \
       [ "$STATIC_RESULT" = "abbey.k-03.com." ]; then

        ok "Record Soal 7 berhasil diterima TEDD."

    else

        fail "Record Soal 7 pada TEDD belum sesuai."
    fi


    garis
    echo "SOAL 7 - KONFIGURASI TEDD SELESAI"
    garis

    exit 0

    # ========================================================
    # STEP 4 - SELESAI SAMPAI SINI
    # ========================================================
fi


# ============================================================
# NODE CLIENT: ALPHA ATAU DELTA
# ============================================================

if [ "$NODE" = "alpha" ] || [ "$NODE" = "delta" ]; then

    # ========================================================
    # STEP 1 - SET DNS CLIENT
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 1/3 - Mengatur resolver pada $NODE"

    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF

    echo
    echo "Isi /etc/resolv.conf:"
    cat /etc/resolv.conf


    if ! command -v host >/dev/null 2>&1; then

        echo
        echo "bind-tools belum tersedia."
        echo "Menjalankan:"
        echo "apk add bind-tools"

        apk add bind-tools \
            || fail "Gagal menginstall bind-tools."
    fi

    ok "Resolver $NODE siap."

    # ========================================================
    # STEP 1 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 2 - TEST VAULT DAN CORE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/3 - Mengecek record vault dan core"
    echo

    echo "Command:"
    echo "host vault.$DOMAIN"
    echo
    host "vault.$DOMAIN"

    echo
    echo "Command:"
    echo "host core.$DOMAIN"
    echo
    host "core.$DOMAIN"

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - TEST CNAME WWW DAN STATIC
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/3 - Mengecek www dan static"
    echo

    echo "Command:"
    echo "host www.$DOMAIN"
    echo
    host "www.$DOMAIN"

    echo
    echo "Command:"
    echo "host static.$DOMAIN"
    echo
    host "static.$DOMAIN"


    WWW_RESULT="$(dig @"$MASTER_IP" "www.$DOMAIN" CNAME +short)"
    STATIC_RESULT="$(dig @"$MASTER_IP" "static.$DOMAIN" CNAME +short)"


    if [ "$WWW_RESULT" = "penny.k-03.com." ] && \
       [ "$STATIC_RESULT" = "abbey.k-03.com." ]; then

        ok "Resolusi vault, core, www, dan static berhasil."

    else

        fail "Ada record Soal 7 yang belum sesuai."
    fi


    garis
    echo "SOAL 7 - VERIFIKASI $NODE SELESAI"
    garis

    exit 0

    # ========================================================
    # STEP 3 - SELESAI SAMPAI SINI
    # ========================================================
fi


# ============================================================
# NODE SALAH
# ============================================================

garis
echo "[GAGAL] Script Soal 7 tidak digunakan pada node: $NODE"
echo
echo "Jalankan script ini pada:"
echo "  - prab"
echo "  - tedd"
echo "  - alpha"
echo "  - delta"
garis

exit 1
