#!/bin/sh

# ============================================================
# K-03 - SOAL 8
# ============================================================

NODE="$(hostname)"

DOMAIN="k-03.com"

MASTER_IP="10.65.2.3"
SLAVE_IP="10.65.2.2"
EXTERNAL_DNS="192.168.122.1"

FORWARD_SERIAL="2026092903"
REVERSE_SERIAL="2026093001"


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
echo " K-03 - SOAL 8"
echo " Node terdeteksi: $NODE"
echo "============================================================"


# ============================================================
# NODE PRAB
# ============================================================

if [ "$NODE" = "prab" ]; then

    # ========================================================
    # STEP 1 - CEK BIND
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 1/7 - Memastikan BIND tersedia"
    echo

    cat > /etc/resolv.conf <<EOF
nameserver $EXTERNAL_DNS
EOF

    if ! apk info -e bind >/dev/null 2>&1; then

        echo "BIND belum tersedia."
        echo "Command:"
        echo "apk add bind bind-tools"
        echo

        apk add bind bind-tools \
            || fail "Gagal menginstall BIND."

    else

        echo "BIND sudah tersedia."

    fi

    if ! command -v dig >/dev/null 2>&1; then

        echo
        echo "bind-tools belum tersedia."
        echo "Command:"
        echo "apk add bind-tools"

        apk add bind-tools \
            || fail "Gagal menginstall bind-tools."

    fi

    ok "BIND dan DNS tools siap."

    # ========================================================
    # STEP 1 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 2 - MEMASTIKAN FORWARD ZONE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/7 - Memastikan forward zone dari Soal 7 tersedia"
    echo

    mkdir -p /etc/bind
    mkdir -p /var/bind

    cat > /var/bind/db.k-03.com <<EOF
\$TTL 86400

@   IN  SOA prab.k-03.com. root.k-03.com. (
        $FORWARD_SERIAL
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

    echo "Forward zone siap dengan serial $FORWARD_SERIAL."

    ok "Forward zone berhasil dipastikan."

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - REVERSE ZONE 10.65.3.0/24
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/7 - Membuat reverse zone 10.65.3.0/24"
    echo

    cat > /var/bind/db.10.65.3 <<EOF
\$TTL 86400

@   IN  SOA prab.k-03.com. root.k-03.com. (
        $REVERSE_SERIAL
        3600
        1800
        604800
        86400
)

@       IN  NS      prab.k-03.com.
@       IN  NS      tedd.k-03.com.

2       IN  PTR     core.k-03.com.
3       IN  PTR     core.k-03.com.

4       IN  PTR     vault.k-03.com.
5       IN  PTR     vault.k-03.com.
EOF

    echo "Isi reverse zone:"
    echo "------------------------------------------------------------"
    cat /var/bind/db.10.65.3
    echo "------------------------------------------------------------"

    ok "Reverse zone 10.65.3.0/24 dibuat."

    # ========================================================
    # STEP 3 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 4 - REVERSE ZONE 10.65.4 DAN 10.65.5
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 4/7 - Membuat reverse zone Abbey dan Penny"
    echo


    echo "Membuat reverse zone 10.65.4.0/24..."

    cat > /var/bind/db.10.65.4 <<EOF
\$TTL 86400

@   IN  SOA prab.k-03.com. root.k-03.com. (
        $REVERSE_SERIAL
        3600
        1800
        604800
        86400
)

@       IN  NS      prab.k-03.com.
@       IN  NS      tedd.k-03.com.

2       IN  PTR     abbey.k-03.com.
EOF


    echo
    echo "Membuat reverse zone 10.65.5.0/24..."

    cat > /var/bind/db.10.65.5 <<EOF
\$TTL 86400

@   IN  SOA prab.k-03.com. root.k-03.com. (
        $REVERSE_SERIAL
        3600
        1800
        604800
        86400
)

@       IN  NS      prab.k-03.com.
@       IN  NS      tedd.k-03.com.

2       IN  PTR     penny.k-03.com.
EOF


    echo
    echo "Reverse 10.65.4.2:"
    grep PTR /var/bind/db.10.65.4

    echo
    echo "Reverse 10.65.5.2:"
    grep PTR /var/bind/db.10.65.5

    ok "Reverse zone Abbey dan Penny dibuat."

    # ========================================================
    # STEP 4 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 5 - KONFIGURASI NAMED.CONF
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 5/7 - Menambahkan reverse zone ke DNS Master"
    echo

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

zone "3.65.10.in-addr.arpa" {
    type master;
    file "db.10.65.3";
    notify yes;
    also-notify { $SLAVE_IP; };
    allow-transfer { $SLAVE_IP; };
};

zone "4.65.10.in-addr.arpa" {
    type master;
    file "db.10.65.4";
    notify yes;
    also-notify { $SLAVE_IP; };
    allow-transfer { $SLAVE_IP; };
};

zone "5.65.10.in-addr.arpa" {
    type master;
    file "db.10.65.5";
    notify yes;
    also-notify { $SLAVE_IP; };
    allow-transfer { $SLAVE_IP; };
};
EOF

    echo
    echo "Reverse zone yang terdaftar:"
    grep '^zone' /etc/bind/named.conf

    ok "Reverse zone berhasil ditambahkan ke named.conf."

    # ========================================================
    # STEP 5 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 6 - VALIDASI DAN RESTART
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 6/7 - Validasi seluruh zone"
    echo


    echo "Command:"
    echo "named-checkconf"
    echo

    named-checkconf \
        || fail "named.conf tidak valid."


    echo
    echo "Validasi forward zone:"
    named-checkzone "$DOMAIN" /var/bind/db.k-03.com \
        || fail "Forward zone tidak valid."


    echo
    echo "Validasi reverse 10.65.3.0/24:"
    named-checkzone "3.65.10.in-addr.arpa" /var/bind/db.10.65.3 \
        || fail "Reverse zone 10.65.3.0/24 tidak valid."


    echo
    echo "Validasi reverse 10.65.4.0/24:"
    named-checkzone "4.65.10.in-addr.arpa" /var/bind/db.10.65.4 \
        || fail "Reverse zone 10.65.4.0/24 tidak valid."


    echo
    echo "Validasi reverse 10.65.5.0/24:"
    named-checkzone "5.65.10.in-addr.arpa" /var/bind/db.10.65.5 \
        || fail "Reverse zone 10.65.5.0/24 tidak valid."


    echo
    echo "Restart DNS Master..."

    killall named 2>/dev/null || true

    named -c /etc/bind/named.conf \
        || fail "DNS Master gagal dijalankan."

    sleep 2


    if ss -lunp | grep -q ':53'; then

        ok "DNS Master aktif pada port 53."

    else

        fail "DNS Master tidak aktif."

    fi

    # ========================================================
    # STEP 6 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 7 - TEST REVERSE DNS
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 7/7 - Verifikasi Reverse DNS pada PRAB"

    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF


    echo
    echo "Command:"
    echo "dig @$MASTER_IP -x 10.65.3.2 +short"
    echo
    dig @"$MASTER_IP" -x 10.65.3.2 +short


    echo
    echo "Command:"
    echo "dig @$MASTER_IP -x 10.65.3.3 +short"
    echo
    dig @"$MASTER_IP" -x 10.65.3.3 +short


    echo
    echo "Command:"
    echo "dig @$MASTER_IP -x 10.65.3.4 +short"
    echo
    dig @"$MASTER_IP" -x 10.65.3.4 +short


    echo
    echo "Command:"
    echo "dig @$MASTER_IP -x 10.65.3.5 +short"
    echo
    dig @"$MASTER_IP" -x 10.65.3.5 +short


    echo
    echo "Command:"
    echo "dig @$MASTER_IP -x 10.65.4.2 +short"
    echo
    dig @"$MASTER_IP" -x 10.65.4.2 +short


    echo
    echo "Command:"
    echo "dig @$MASTER_IP -x 10.65.5.2 +short"
    echo
    dig @"$MASTER_IP" -x 10.65.5.2 +short


    CORE_RESULT="$(dig @"$MASTER_IP" -x 10.65.3.2 +short)"
    VAULT_RESULT="$(dig @"$MASTER_IP" -x 10.65.3.5 +short)"
    ABBEY_RESULT="$(dig @"$MASTER_IP" -x 10.65.4.2 +short)"
    PENNY_RESULT="$(dig @"$MASTER_IP" -x 10.65.5.2 +short)"


    if [ "$CORE_RESULT" = "core.k-03.com." ] && \
       [ "$VAULT_RESULT" = "vault.k-03.com." ] && \
       [ "$ABBEY_RESULT" = "abbey.k-03.com." ] && \
       [ "$PENNY_RESULT" = "penny.k-03.com." ]; then

        ok "Reverse DNS pada PRAB berhasil."

    else

        fail "Ada PTR record yang belum sesuai."
    fi


    garis
    echo "SOAL 8 - KONFIGURASI PRAB SELESAI"
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
    # STEP 2 - KONFIGURASI SLAVE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/5 - Menambahkan reverse zone pada DNS Slave"
    echo


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

zone "3.65.10.in-addr.arpa" {
    type slave;
    masters { $MASTER_IP; };
    file "slaves/db.10.65.3";
};

zone "4.65.10.in-addr.arpa" {
    type slave;
    masters { $MASTER_IP; };
    file "slaves/db.10.65.4";
};

zone "5.65.10.in-addr.arpa" {
    type slave;
    masters { $MASTER_IP; };
    file "slaves/db.10.65.5";
};
EOF


    echo "Reverse zone pada TEDD:"
    grep '^zone' /etc/bind/named.conf


    named-checkconf \
        || fail "Konfigurasi DNS Slave tidak valid."


    ok "Konfigurasi TEDD valid."

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 3 - TRANSFER REVERSE ZONE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 3/5 - Mengambil reverse zone dari PRAB"
    echo

    echo "Menghapus salinan zone lama..."

    rm -f /var/bind/slaves/db.k-03.com
    rm -f /var/bind/slaves/db.10.65.3
    rm -f /var/bind/slaves/db.10.65.4
    rm -f /var/bind/slaves/db.10.65.5


    echo
    echo "Restart DNS Slave..."

    killall named 2>/dev/null || true

    named -c /etc/bind/named.conf \
        || fail "DNS Slave gagal dijalankan."


    echo
    echo "Menunggu zone transfer..."

    sleep 4

    # ========================================================
    # STEP 3 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 4 - CEK SERIAL REVERSE ZONE
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 4/5 - Mengecek serial reverse zone PRAB dan TEDD"
    echo


    echo "Reverse 10.65.3.0/24 pada PRAB:"
    MASTER_REVERSE_SERIAL="$(dig @"$MASTER_IP" "3.65.10.in-addr.arpa" SOA +short | awk '{print $3}')"
    echo "$MASTER_REVERSE_SERIAL"


    echo
    echo "Reverse 10.65.3.0/24 pada TEDD:"
    SLAVE_REVERSE_SERIAL="$(dig @"$SLAVE_IP" "3.65.10.in-addr.arpa" SOA +short | awk '{print $3}')"
    echo "$SLAVE_REVERSE_SERIAL"


    echo
    echo "Serial yang diharapkan : $REVERSE_SERIAL"
    echo "Serial PRAB            : $MASTER_REVERSE_SERIAL"
    echo "Serial TEDD            : $SLAVE_REVERSE_SERIAL"


    if [ "$MASTER_REVERSE_SERIAL" = "$REVERSE_SERIAL" ] && \
       [ "$SLAVE_REVERSE_SERIAL" = "$REVERSE_SERIAL" ]; then

        ok "Reverse zone sudah sinkron."

    else

        fail "Reverse zone PRAB dan TEDD belum sinkron."
    fi

    # ========================================================
    # STEP 4 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 5 - TEST PTR PADA TEDD
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 5/5 - Verifikasi PTR melalui DNS Slave"

    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF


    echo
    echo "10.65.3.2:"
    dig @"$SLAVE_IP" -x 10.65.3.2 +short

    echo
    echo "10.65.3.5:"
    dig @"$SLAVE_IP" -x 10.65.3.5 +short

    echo
    echo "10.65.4.2:"
    dig @"$SLAVE_IP" -x 10.65.4.2 +short

    echo
    echo "10.65.5.2:"
    dig @"$SLAVE_IP" -x 10.65.5.2 +short


    CORE_RESULT="$(dig @"$SLAVE_IP" -x 10.65.3.2 +short)"
    VAULT_RESULT="$(dig @"$SLAVE_IP" -x 10.65.3.5 +short)"
    ABBEY_RESULT="$(dig @"$SLAVE_IP" -x 10.65.4.2 +short)"
    PENNY_RESULT="$(dig @"$SLAVE_IP" -x 10.65.5.2 +short)"


    if [ "$CORE_RESULT" = "core.k-03.com." ] && \
       [ "$VAULT_RESULT" = "vault.k-03.com." ] && \
       [ "$ABBEY_RESULT" = "abbey.k-03.com." ] && \
       [ "$PENNY_RESULT" = "penny.k-03.com." ]; then

        ok "PTR record berhasil diterima DNS Slave."

    else

        fail "PTR record pada TEDD belum sesuai."
    fi


    garis
    echo "SOAL 8 - KONFIGURASI TEDD SELESAI"
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
    echo "STEP 1/2 - Mengatur resolver Alpha"
    echo


    cat > /etc/resolv.conf <<EOF
nameserver $MASTER_IP
nameserver $SLAVE_IP
nameserver $EXTERNAL_DNS
EOF


    if ! command -v dig >/dev/null 2>&1; then

        echo "bind-tools belum tersedia."
        echo "Menjalankan:"
        echo "apk add bind-tools"
        echo

        apk add bind-tools \
            || fail "Gagal menginstall bind-tools."

    fi


    echo "Isi /etc/resolv.conf:"
    cat /etc/resolv.conf

    ok "Resolver Alpha siap."

    # ========================================================
    # STEP 1 - SELESAI SAMPAI SINI
    # ========================================================


    # ========================================================
    # STEP 2 - VERIFIKASI REVERSE DNS
    # MULAI DARI SINI
    # ========================================================

    garis
    echo "STEP 2/2 - Menguji Reverse DNS dari Alpha"
    echo


    echo "------------------------------------------------------------"
    echo "10.65.3.2"
    echo "Command: dig -x 10.65.3.2 +short"
    echo "------------------------------------------------------------"
    dig -x 10.65.3.2 +short


    echo
    echo "------------------------------------------------------------"
    echo "10.65.3.3"
    echo "Command: dig -x 10.65.3.3 +short"
    echo "------------------------------------------------------------"
    dig -x 10.65.3.3 +short


    echo
    echo "------------------------------------------------------------"
    echo "10.65.3.4"
    echo "Command: dig -x 10.65.3.4 +short"
    echo "------------------------------------------------------------"
    dig -x 10.65.3.4 +short


    echo
    echo "------------------------------------------------------------"
    echo "10.65.3.5"
    echo "Command: dig -x 10.65.3.5 +short"
    echo "------------------------------------------------------------"
    dig -x 10.65.3.5 +short


    echo
    echo "------------------------------------------------------------"
    echo "10.65.4.2"
    echo "Command: dig -x 10.65.4.2 +short"
    echo "------------------------------------------------------------"
    dig -x 10.65.4.2 +short


    echo
    echo "------------------------------------------------------------"
    echo "10.65.5.2"
    echo "Command: dig -x 10.65.5.2 +short"
    echo "------------------------------------------------------------"
    dig -x 10.65.5.2 +short


    CORE_RESULT="$(dig -x 10.65.3.2 +short)"
    VAULT_RESULT="$(dig -x 10.65.3.5 +short)"
    ABBEY_RESULT="$(dig -x 10.65.4.2 +short)"
    PENNY_RESULT="$(dig -x 10.65.5.2 +short)"


    if [ "$CORE_RESULT" = "core.k-03.com." ] && \
       [ "$VAULT_RESULT" = "vault.k-03.com." ] && \
       [ "$ABBEY_RESULT" = "abbey.k-03.com." ] && \
       [ "$PENNY_RESULT" = "penny.k-03.com." ]; then

        ok "Semua Reverse DNS utama berhasil."

    else

        fail "Ada Reverse DNS yang belum sesuai."
    fi


    garis
    echo "HASIL AKHIR SOAL 8"
    echo "------------------------------------------------------------"
    echo "10.65.3.2 -> core.k-03.com"
    echo "10.65.3.3 -> core.k-03.com"
    echo "10.65.3.4 -> vault.k-03.com"
    echo "10.65.3.5 -> vault.k-03.com"
    echo "10.65.4.2 -> abbey.k-03.com"
    echo "10.65.5.2 -> penny.k-03.com"
    echo
    echo "[OK] Reverse DNS berhasil."
    garis


    exit 0

    # ========================================================
    # STEP 2 - SELESAI SAMPAI SINI
    # ========================================================
fi


# ============================================================
# NODE SALAH
# ============================================================

garis
echo "[GAGAL] Script Soal 8 tidak digunakan pada node: $NODE"
echo
echo "Jalankan script ini pada:"
echo "  - prab"
echo "  - tedd"
echo "  - alpha"
garis

exit 1
