#!/bin/sh

# ============================================================
# K-03 - SOAL 5
# ============================================================

NODE="$(hostname)"

DOMAIN="k-03.com"

MASTER_IP="10.65.2.3"
SLAVE_IP="10.65.2.2"
EXTERNAL_DNS="192.168.122.1"

SERIAL="2026092902"


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
echo " K-03 - SOAL 5"
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
        echo "bind-tools belum tersedia."
        echo "Menjalankan: apk add bind bind-tools"

        cat > /etc/resolv.conf <<EOF
nameserver $EXTERNAL_DNS
EOF

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
    echo "STEP 2/6 - Memastikan PRAB tetap sebagai DNS Master"

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
    echo "Isi konfigurasi DNS Master:"
    echo "------------------------------------------------------------"
    cat /etc/bind/named.conf
    echo "------------------------------------------------------------"

    ok "Konfigurasi DNS Master siap."

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - MENAMBAHKAN SELURUH RECORD A
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/6 - Menambahkan seluruh record A K-03"
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

prab        IN  A   10.65.2.3
tedd        IN  A   10.65.2.2

rootkit     IN  A   10.65.1.1

alpha       IN  A   10.65.6.2
beta        IN  A   10.65.6.3
gamma       IN  A   10.65.6.4

delta       IN  A   10.65.7.2
epsilon     IN  A   10.65.7.3

abbey       IN  A   10.65.4.2
penny       IN  A   10.65.5.2

obladi      IN  A   10.65.3.5
desmond     IN  A   10.65.3.4

oblada      IN  A   10.65.3.3
molly       IN  A   10.65.3.2
EOF

    echo
    echo "Isi zone terbaru:"
    echo "------------------------------------------------------------"
    cat /var/bind/db.k-03.com
    echo "------------------------------------------------------------"

    ok "Seluruh record A berhasil ditulis."

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

    ok "Konfigurasi dan zone valid."

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
    echo "Menghentikan named lama jika masih aktif..."

    killall named 2>/dev/null || true

    echo
    echo "Menjalankan:"
    echo "named -c /etc/bind/named.conf"
    echo

    named -c /etc/bind/named.conf \
        || fail "BIND gagal dijalankan."

    sleep 2

    if ss -lunp | grep -q ':53'; then
        ok "DNS Master aktif di port 53."
    else
        fail "DNS Master tidak aktif di port 53."
    fi

    # ========================================================
    # STEP 5 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 6 - VERIFIKASI RECORD
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 6/6 - Verifikasi record DNS PRAB"

    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF

    echo
    echo "Cek serial SOA:"
    echo

    dig @"$MASTER_IP" "$DOMAIN" SOA +short

    CURRENT_SERIAL="$(dig @"$MASTER_IP" "$DOMAIN" SOA +short | awk '{print $3}')"

    if [ "$CURRENT_SERIAL" = "$SERIAL" ]; then
        ok "Serial PRAB sesuai: $CURRENT_SERIAL"
    else
        fail "Serial PRAB tidak sesuai."
    fi


    echo
    echo "------------------------------------------------------------"
    echo "Pengecekan beberapa record:"
    echo "------------------------------------------------------------"

    echo
    echo "molly.$DOMAIN"
    dig @"$MASTER_IP" "molly.$DOMAIN" A +short

    echo
    echo "oblada.$DOMAIN"
    dig @"$MASTER_IP" "oblada.$DOMAIN" A +short

    echo
    echo "beta.$DOMAIN"
    dig @"$MASTER_IP" "beta.$DOMAIN" A +short

    echo
    echo "abbey.$DOMAIN"
    dig @"$MASTER_IP" "abbey.$DOMAIN" A +short

    echo
    echo "penny.$DOMAIN"
    dig @"$MASTER_IP" "penny.$DOMAIN" A +short


    MOLLY_RESULT="$(dig @"$MASTER_IP" "molly.$DOMAIN" A +short)"
    BETA_RESULT="$(dig @"$MASTER_IP" "beta.$DOMAIN" A +short)"

    if [ "$MOLLY_RESULT" = "10.65.3.2" ] && \
       [ "$BETA_RESULT" = "10.65.6.3" ]; then

        ok "Record DNS pada PRAB berhasil."

    else

        fail "Ada record DNS yang belum sesuai."
    fi


    garis
    echo "SOAL 5 - KONFIGURASI PRAB SELESAI"
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
    # STEP 1 - CEK KONEKSI KE PRAB
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 1/5 - Mengecek koneksi TEDD ke PRAB"
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
    # STEP 2 - MEMASTIKAN KONFIGURASI SLAVE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/5 - Memastikan TEDD sebagai DNS Slave"

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

    echo
    echo "Isi konfigurasi TEDD:"
    echo "------------------------------------------------------------"
    cat /etc/bind/named.conf
    echo "------------------------------------------------------------"

    named-checkconf \
        || fail "Konfigurasi TEDD tidak valid."

    ok "Konfigurasi DNS Slave valid."

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - SINKRONISASI ZONE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/5 - Mengambil zone terbaru dari PRAB"

    echo
    echo "Menghapus cache zone Slave lama..."
    rm -f /var/bind/slaves/db.k-03.com

    echo
    echo "Restart named..."

    killall named 2>/dev/null || true

    named -c /etc/bind/named.conf \
        || fail "DNS Slave gagal dijalankan."

    echo
    echo "Menunggu proses zone transfer..."

    sleep 3

    # ========================================================
    # STEP 3 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 4 - CEK SERIAL MASTER DAN SLAVE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 4/5 - Mengecek serial PRAB dan TEDD"

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


    if [ "$MASTER_SERIAL" = "$SERIAL" ] && \
       [ "$SLAVE_SERIAL" = "$SERIAL" ]; then

        ok "PRAB dan TEDD sudah sinkron."

    else

        fail "PRAB dan TEDD belum sinkron."
    fi

    # ========================================================
    # STEP 4 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 5 - VERIFIKASI RECORD PADA SLAVE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 5/5 - Memeriksa record yang diterima TEDD"

    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF


    echo
    echo "Record molly:"
    dig @"$SLAVE_IP" "molly.$DOMAIN" A +short

    echo
    echo "Record beta:"
    dig @"$SLAVE_IP" "beta.$DOMAIN" A +short

    echo
    echo "Record oblada:"
    dig @"$SLAVE_IP" "oblada.$DOMAIN" A +short


    MOLLY_RESULT="$(dig @"$SLAVE_IP" "molly.$DOMAIN" A +short)"
    BETA_RESULT="$(dig @"$SLAVE_IP" "beta.$DOMAIN" A +short)"


    if [ "$MOLLY_RESULT" = "10.65.3.2" ] && \
       [ "$BETA_RESULT" = "10.65.6.3" ]; then

        ok "TEDD berhasil menerima record terbaru."

    else

        fail "Record pada TEDD belum sesuai."
    fi


    garis
    echo "SOAL 5 - KONFIGURASI TEDD SELESAI"
    garis

    exit 0

    # ========================================================
    # STEP 5 - SELESAI SAMPAI SINI
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

    if ! command -v host >/dev/null 2>&1; then

        echo
        echo "bind-tools belum tersedia."
        echo "Menjalankan: apk add bind-tools"

        apk add bind-tools \
            || fail "Gagal menginstall bind-tools."

    fi

    ok "Resolver Alpha siap."

    # ========================================================
    # STEP 1 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 2 - CEK SELURUH RECORD
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/3 - Mengecek record DNS K-03"
    echo


    echo "---- rootkit ----"
    host "rootkit.$DOMAIN"

    echo
    echo "---- alpha ----"
    host "alpha.$DOMAIN"

    echo
    echo "---- beta ----"
    host "beta.$DOMAIN"

    echo
    echo "---- gamma ----"
    host "gamma.$DOMAIN"

    echo
    echo "---- delta ----"
    host "delta.$DOMAIN"

    echo
    echo "---- epsilon ----"
    host "epsilon.$DOMAIN"

    echo
    echo "---- abbey ----"
    host "abbey.$DOMAIN"

    echo
    echo "---- penny ----"
    host "penny.$DOMAIN"

    echo
    echo "---- obladi ----"
    host "obladi.$DOMAIN"

    echo
    echo "---- desmond ----"
    host "desmond.$DOMAIN"

    echo
    echo "---- oblada ----"
    host "oblada.$DOMAIN"

    echo
    echo "---- molly ----"
    host "molly.$DOMAIN"

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - VERIFIKASI AKHIR
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/3 - Verifikasi akhir Soal 5"

    ALPHA_RESULT="$(host "alpha.$DOMAIN" | awk '/has address/ {print $4}')"
    BETA_RESULT="$(host "beta.$DOMAIN" | awk '/has address/ {print $4}')"
    ABBEY_RESULT="$(host "abbey.$DOMAIN" | awk '/has address/ {print $4}')"
    PENNY_RESULT="$(host "penny.$DOMAIN" | awk '/has address/ {print $4}')"
    OBLADA_RESULT="$(host "oblada.$DOMAIN" | awk '/has address/ {print $4}')"
    MOLLY_RESULT="$(host "molly.$DOMAIN" | awk '/has address/ {print $4}')"


    echo
    echo "Alpha  : $ALPHA_RESULT"
    echo "Beta   : $BETA_RESULT"
    echo "Abbey  : $ABBEY_RESULT"
    echo "Penny  : $PENNY_RESULT"
    echo "Oblada : $OBLADA_RESULT"
    echo "Molly  : $MOLLY_RESULT"


    if [ "$ALPHA_RESULT" = "10.65.6.2" ] && \
       [ "$BETA_RESULT" = "10.65.6.3" ] && \
       [ "$ABBEY_RESULT" = "10.65.4.2" ] && \
       [ "$PENNY_RESULT" = "10.65.5.2" ] && \
       [ "$OBLADA_RESULT" = "10.65.3.3" ] && \
       [ "$MOLLY_RESULT" = "10.65.3.2" ]; then

        ok "Seluruh record utama Soal 5 berhasil di-resolve."

    else

        fail "Ada record DNS yang belum sesuai."
    fi


    garis
    echo "SOAL 5 - VERIFIKASI ALPHA SELESAI"
    garis

    exit 0

    # ========================================================
    # STEP 3 - SELESAI SAMPAI SINI
    # ========================================================
fi


# ============================================================
# JIKA DIJALANKAN DI NODE YANG SALAH
# ============================================================

garis
echo "[GAGAL] Script Soal 5 tidak digunakan pada node: $NODE"
echo
echo "Jalankan script ini pada:"
echo "  - prab"
echo "  - tedd"
echo "  - alpha"
garis

exit 1
