#!/bin/sh

# ============================================================
# K-03 - SOAL 4
# ============================================================

NODE="$(hostname)"
DOMAIN="k-03.com"

MASTER_IP="10.65.2.3"
SLAVE_IP="10.65.2.2"
EXTERNAL_DNS="192.168.122.1"

SERIAL="2026092901"


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
echo " K-03 - SOAL 4"
echo " Node terdeteksi: $NODE"
echo "============================================================"


# ============================================================
# NODE PRAB
# ============================================================

if [ "$NODE" = "prab" ]; then

    # ========================================================
    # STEP 1 - CEK KONEKSI
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 1/7 - Mengecek koneksi PRAB ke gateway"
    echo
    echo "Command:"
    echo "ping -c 2 10.65.2.1"
    echo

    if ping -c 2 10.65.2.1; then
        ok "PRAB dapat menghubungi gateway."
    else
        fail "PRAB tidak dapat menghubungi gateway 10.65.2.1."
    fi

    # ========================================================
    # STEP 1 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 2 - DNS SEMENTARA
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/7 - Mengatur DNS sementara untuk instalasi paket"
    echo
    echo "Command yang dijalankan:"
    echo "nameserver $EXTERNAL_DNS"

    cat > /etc/resolv.conf <<EOF
nameserver $EXTERNAL_DNS
EOF

    echo
    cat /etc/resolv.conf

    ok "DNS sementara sudah diatur."

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - INSTALL BIND
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/7 - Memastikan BIND dan bind-tools tersedia"
    echo

    if apk info -e bind >/dev/null 2>&1; then
        echo "bind sudah terinstall."
    else
        echo "Menjalankan: apk add bind"
        apk add bind || fail "Install bind gagal."
    fi

    if apk info -e bind-tools >/dev/null 2>&1; then
        echo "bind-tools sudah terinstall."
    else
        echo "Menjalankan: apk add bind-tools"
        apk add bind-tools || fail "Install bind-tools gagal."
    fi

    ok "BIND dan bind-tools siap."

    # ========================================================
    # STEP 3 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 4 - KONFIGURASI DNS MASTER
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 4/7 - Membuat konfigurasi DNS Master PRAB"

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

    ok "Konfigurasi DNS Master dibuat."

    # ========================================================
    # STEP 4 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 5 - MEMBUAT ZONE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 5/7 - Membuat zone awal $DOMAIN"

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
prab    IN  A       $MASTER_IP
tedd    IN  A       $SLAVE_IP
EOF

    echo
    echo "Isi zone:"
    echo "------------------------------------------------------------"
    cat /var/bind/db.k-03.com
    echo "------------------------------------------------------------"

    ok "Zone $DOMAIN sudah dibuat."

    # ========================================================
    # STEP 5 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 6 - VALIDASI DAN START DNS
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 6/7 - Validasi konfigurasi DNS"
    echo
    echo "Command:"
    echo "named-checkconf"
    echo

    named-checkconf || fail "named.conf tidak valid."

    echo
    echo "Command:"
    echo "named-checkzone $DOMAIN /var/bind/db.k-03.com"
    echo

    named-checkzone "$DOMAIN" /var/bind/db.k-03.com \
        || fail "Zone $DOMAIN tidak valid."

    echo
    echo "Restart DNS Master..."

    killall named 2>/dev/null || true

    named -c /etc/bind/named.conf \
        || fail "BIND gagal dijalankan."

    sleep 1

    if ss -lunp | grep -q ':53'; then
        ok "DNS Master aktif di port 53."
    else
        fail "DNS Master belum aktif di port 53."
    fi

    # ========================================================
    # STEP 6 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 7 - VERIFIKASI
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 7/7 - Verifikasi DNS Master PRAB"

    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF

    echo
    echo "Cek record domain utama:"
    echo "Command:"
    echo "dig @$MASTER_IP $DOMAIN A +short"
    echo

    dig @"$MASTER_IP" "$DOMAIN" A +short

    echo
    echo "Cek record PRAB:"
    dig @"$MASTER_IP" "prab.$DOMAIN" A +short

    echo
    echo "Cek record TEDD:"
    dig @"$MASTER_IP" "tedd.$DOMAIN" A +short

    echo
    echo "Cek serial SOA:"
    dig @"$MASTER_IP" "$DOMAIN" SOA +short

    CURRENT_SERIAL="$(dig @"$MASTER_IP" "$DOMAIN" SOA +short | awk '{print $3}')"

    if [ "$CURRENT_SERIAL" = "$SERIAL" ]; then
        ok "Serial DNS sesuai: $CURRENT_SERIAL"
    else
        fail "Serial DNS tidak sesuai."
    fi

    garis
    echo "SOAL 4 - KONFIGURASI PRAB SELESAI"
    garis

    exit 0

    # ========================================================
    # STEP 7 - SELESAI SAMPAI SINI
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
    echo "STEP 1/6 - Mengecek koneksi TEDD ke PRAB"
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
    # STEP 2 - INSTALL BIND
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/6 - Memastikan BIND tersedia"

    cat > /etc/resolv.conf <<EOF
nameserver $EXTERNAL_DNS
EOF

    if ! apk info -e bind >/dev/null 2>&1; then
        echo
        echo "Menjalankan: apk add bind"
        apk add bind || fail "Install bind gagal."
    else
        echo "bind sudah terinstall."
    fi

    if ! apk info -e bind-tools >/dev/null 2>&1; then
        echo
        echo "Menjalankan: apk add bind-tools"
        apk add bind-tools || fail "Install bind-tools gagal."
    else
        echo "bind-tools sudah terinstall."
    fi

    ok "BIND siap."

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - KONFIGURASI DNS SLAVE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/6 - Membuat konfigurasi DNS Slave TEDD"

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

    echo
    echo "Isi /etc/bind/named.conf:"
    echo "------------------------------------------------------------"
    cat /etc/bind/named.conf
    echo "------------------------------------------------------------"

    ok "Konfigurasi DNS Slave dibuat."

    # ========================================================
    # STEP 3 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 4 - VALIDASI DAN START
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 4/6 - Validasi dan menjalankan DNS Slave"

    echo
    echo "Command:"
    echo "named-checkconf"
    echo

    named-checkconf || fail "Konfigurasi TEDD tidak valid."

    killall named 2>/dev/null || true

    named -c /etc/bind/named.conf \
        || fail "DNS Slave gagal dijalankan."

    sleep 2

    if ss -lunp | grep -q ':53'; then
        ok "DNS Slave aktif di port 53."
    else
        fail "DNS Slave belum aktif."
    fi

    # ========================================================
    # STEP 4 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 5 - CEK TRANSFER ZONE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 5/6 - Mengecek sinkronisasi PRAB dan TEDD"

    echo
    echo "SOA PRAB:"
    dig @"$MASTER_IP" "$DOMAIN" SOA +short

    echo
    echo "SOA TEDD:"
    dig @"$SLAVE_IP" "$DOMAIN" SOA +short

    MASTER_SERIAL="$(dig @"$MASTER_IP" "$DOMAIN" SOA +short | awk '{print $3}')"
    SLAVE_SERIAL="$(dig @"$SLAVE_IP" "$DOMAIN" SOA +short | awk '{print $3}')"

    echo
    echo "Serial PRAB : $MASTER_SERIAL"
    echo "Serial TEDD : $SLAVE_SERIAL"

    if [ "$MASTER_SERIAL" = "$SLAVE_SERIAL" ] && \
       [ "$SLAVE_SERIAL" = "$SERIAL" ]; then
        ok "DNS Slave sudah sinkron dengan Master."
    else
        fail "Serial PRAB dan TEDD belum sinkron."
    fi

    # ========================================================
    # STEP 5 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 6 - VERIFIKASI
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 6/6 - Verifikasi akhir TEDD"

    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF

    echo
    echo "Query domain melalui DNS Slave:"
    echo

    dig @"$SLAVE_IP" "$DOMAIN" A +noall +comments +answer

    echo
    echo "Tes AXFR dari PRAB:"
    echo

    dig @"$MASTER_IP" "$DOMAIN" AXFR

    ok "DNS Slave TEDD berhasil."

    garis
    echo "SOAL 4 - KONFIGURASI TEDD SELESAI"
    garis

    exit 0

    # ========================================================
    # STEP 6 - SELESAI SAMPAI SINI
    # ========================================================
fi


# ============================================================
# NODE ALPHA
# ============================================================

if [ "$NODE" = "alpha" ]; then

    # ========================================================
    # STEP 1 - SET DNS CLIENT
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 1/3 - Mengatur DNS client Alpha"

    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF

    echo
    echo "Isi /etc/resolv.conf:"
    cat /etc/resolv.conf

    ok "DNS client Alpha sudah diatur."

    # ========================================================
    # STEP 1 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 2 - CEK RESOLUSI
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/3 - Mengecek resolusi domain"

    if ! command -v host >/dev/null 2>&1; then
        echo
        echo "bind-tools belum tersedia."
        echo "Menginstall bind-tools..."

        apk add bind-tools || fail "Install bind-tools gagal."
    fi

    echo
    echo "Command:"
    echo "host prab.$DOMAIN"
    host "prab.$DOMAIN"

    echo
    echo "Command:"
    echo "host tedd.$DOMAIN"
    host "tedd.$DOMAIN"

    echo
    echo "Command:"
    echo "host $DOMAIN"
    host "$DOMAIN"

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - VERIFIKASI AKHIR
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/3 - Verifikasi DNS Master dan Slave"

    echo
    echo "Query SOA melalui PRAB:"
    dig @"$MASTER_IP" "$DOMAIN" SOA +short

    echo
    echo "Query SOA melalui TEDD:"
    dig @"$SLAVE_IP" "$DOMAIN" SOA +short

    PRAB_RESULT="$(host "prab.$DOMAIN" | awk '/has address/ {print $4}')"
    TEDD_RESULT="$(host "tedd.$DOMAIN" | awk '/has address/ {print $4}')"

    echo
    echo "Hasil PRAB : $PRAB_RESULT"
    echo "Hasil TEDD : $TEDD_RESULT"

    if [ "$PRAB_RESULT" = "$MASTER_IP" ] && \
       [ "$TEDD_RESULT" = "$SLAVE_IP" ]; then

        ok "Resolusi DNS Alpha berhasil."

    else

        fail "Resolusi DNS Alpha tidak sesuai."

    fi

    garis
    echo "SOAL 4 - KONFIGURASI ALPHA SELESAI"
    garis

    exit 0

    # ========================================================
    # STEP 3 - SELESAI SAMPAI SINI
    # ========================================================
fi


# ============================================================
# JIKA SCRIPT DIJALANKAN DI NODE YANG SALAH
# ============================================================

garis
echo "[GAGAL] Script Soal 4 tidak digunakan pada node: $NODE"
echo
echo "Jalankan script ini pada:"
echo "  - prab"
echo "  - tedd"
echo "  - alpha"
garis

exit 1
