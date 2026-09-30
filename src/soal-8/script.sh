#!/bin/sh

# ============================================================
# SOAL 8
# Konfigurasi Reverse DNS
#
# PRAB : 10.65.2.3 -> Reverse DNS Master
# TEDD : 10.65.2.2 -> Reverse DNS Slave
#
# Reverse zone:
# 10.65.3.0/24 -> 3.65.10.in-addr.arpa
# 10.65.4.0/24 -> 4.65.10.in-addr.arpa
# 10.65.5.0/24 -> 5.65.10.in-addr.arpa
# ============================================================


# ============================================================
# [PRAB]
# Tambahkan deklarasi reverse zone ke named.conf
# ============================================================

cat >> /etc/bind/named.conf <<'CONF'

zone "3.65.10.in-addr.arpa" {
    type master;
    file "db.10.65.3";

    notify yes;
    also-notify { 10.65.2.2; };
    allow-transfer { 10.65.2.2; };
};

zone "4.65.10.in-addr.arpa" {
    type master;
    file "db.10.65.4";

    notify yes;
    also-notify { 10.65.2.2; };
    allow-transfer { 10.65.2.2; };
};

zone "5.65.10.in-addr.arpa" {
    type master;
    file "db.10.65.5";

    notify yes;
    also-notify { 10.65.2.2; };
    allow-transfer { 10.65.2.2; };
};
CONF


# ============================================================
# [PRAB]
# Reverse zone untuk area Core dan Vault
# ============================================================

cat > /var/bind/db.10.65.3 <<'ZONE'
$TTL 86400

@   IN SOA prab.k-03.com. root.k-03.com. (
        2026093001
        3600
        1800
        604800
        86400
)

@   IN NS prab.k-03.com.
@   IN NS tedd.k-03.com.

2   IN PTR core.k-03.com.
3   IN PTR core.k-03.com.
4   IN PTR vault.k-03.com.
5   IN PTR vault.k-03.com.
ZONE


# ============================================================
# [PRAB]
# Reverse zone untuk Abbey
# ============================================================

cat > /var/bind/db.10.65.4 <<'ZONE'
$TTL 86400

@   IN SOA prab.k-03.com. root.k-03.com. (
        2026093001
        3600
        1800
        604800
        86400
)

@   IN NS prab.k-03.com.
@   IN NS tedd.k-03.com.

2   IN PTR abbey.k-03.com.
ZONE


# ============================================================
# [PRAB]
# Reverse zone untuk Penny
# ============================================================

cat > /var/bind/db.10.65.5 <<'ZONE'
$TTL 86400

@   IN SOA prab.k-03.com. root.k-03.com. (
        2026093001
        3600
        1800
        604800
        86400
)

@   IN NS prab.k-03.com.
@   IN NS tedd.k-03.com.

2   IN PTR penny.k-03.com.
ZONE


# ============================================================
# [PRAB]
# Validasi dan reload DNS Master
# ============================================================

named-checkconf

named-checkzone 3.65.10.in-addr.arpa /var/bind/db.10.65.3
named-checkzone 4.65.10.in-addr.arpa /var/bind/db.10.65.4
named-checkzone 5.65.10.in-addr.arpa /var/bind/db.10.65.5

killall named 2>/dev/null || true
named -c /etc/bind/named.conf


# ============================================================
# [PRAB]
# Verifikasi Reverse Lookup
# ============================================================

# dig @10.65.2.3 -x 10.65.4.2 +short
# dig @10.65.2.3 -x 10.65.5.2 +short
# dig @10.65.2.3 -x 10.65.3.5 +short
# dig @10.65.2.3 -x 10.65.3.4 +short
# dig @10.65.2.3 -x 10.65.3.3 +short
# dig @10.65.2.3 -x 10.65.3.2 +short


# ============================================================
# [TEDD]
# Tambahkan reverse zone sebagai slave
# ============================================================

mkdir -p /var/bind/slaves
chown named:named /var/bind/slaves 2>/dev/null || true

cat >> /etc/bind/named.conf <<'CONF'

zone "3.65.10.in-addr.arpa" {
    type slave;
    masters { 10.65.2.3; };
    file "slaves/db.10.65.3";
};

zone "4.65.10.in-addr.arpa" {
    type slave;
    masters { 10.65.2.3; };
    file "slaves/db.10.65.4";
};

zone "5.65.10.in-addr.arpa" {
    type slave;
    masters { 10.65.2.3; };
    file "slaves/db.10.65.5";
};
CONF

named-checkconf

killall named 2>/dev/null || true
named -c /etc/bind/named.conf


# ============================================================
# [TEDD]
# Verifikasi Reverse Lookup dari DNS Slave
# ============================================================

# dig @10.65.2.2 -x 10.65.4.2
# dig @10.65.2.2 -x 10.65.5.2
# dig @10.65.2.2 -x 10.65.3.5
# dig @10.65.2.2 -x 10.65.3.2


# ============================================================
# HASIL YANG DIHARAPKAN
# ============================================================

# 10.65.4.2 -> abbey.k-03.com.
# 10.65.5.2 -> penny.k-03.com.
#
# 10.65.3.5 -> vault.k-03.com.
# 10.65.3.4 -> vault.k-03.com.
#
# 10.65.3.3 -> core.k-03.com.
# 10.65.3.2 -> core.k-03.com.
#
# Hasil dig dari PRAB maupun TEDD harus
# mengembalikan PTR record yang sesuai.
# Pada TEDD harus terlihat flag "aa"
# sebagai authoritative answer.
