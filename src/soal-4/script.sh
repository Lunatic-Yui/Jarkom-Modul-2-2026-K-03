#!/bin/sh

# SOAL 4
# Authoritative DNS Master-Slave
# Domain : k-03.com
#
# ROOTKIT
# PRAB : 10.65.2.3 -> DNS Master
# TEDD : 10.65.2.2 -> DNS Slave
# PENNY: 10.65.5.2 -> Apex k-03.com
#
# CATATAN:
# File ini berisi command untuk beberapa node.
# Jalankan hanya bagian yang sesuai pada node terkait.


# [ROOTKIT]
# Menambahkan gateway untuk jaringan DNS dan Core/Vault
# pada interface eth1

ip addr show eth1 | grep -q '10.65.2.1/24' || \
ip addr add 10.65.2.1/24 dev eth1

ip addr show eth1 | grep -q '10.65.3.1/24' || \
ip addr add 10.65.3.1/24 dev eth1


# ============================================================
# [ROOTKIT]
# Verifikasi
# ============================================================

# ip addr show eth1
# ip route | grep '10.65'

# Hasil yang diharapkan pada eth1:
# 10.65.1.1/24
# 10.65.2.1/24
# 10.65.3.1/24


# [PRAB]
# Install BIND dan konfigurasi DNS Master

apk update
apk add bind bind-tools

mkdir -p /var/bind

cat > /etc/bind/named.conf <<'CONF'
options {
    directory "/var/bind";

    listen-on { any; };
    listen-on-v6 { none; };

    allow-query { any; };

    recursion yes;
    dnssec-validation no;

    forwarders {
        192.168.122.1;
    };
};

zone "k-03.com" {
    type master;
    file "db.k-03.com";

    notify yes;
    also-notify { 10.65.2.2; };
    allow-transfer { 10.65.2.2; };
};
CONF


# ============================================================
# [PRAB]
# Forward Zone k-03.com
# ============================================================

cat > /var/bind/db.k-03.com <<'ZONE'
$TTL 86400

@   IN  SOA prab.k-03.com. root.k-03.com. (
        2026092901
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
ZONE


# ============================================================
# [PRAB]
# Validasi dan menjalankan DNS Master
# ============================================================

named-checkconf
named-checkzone k-03.com /var/bind/db.k-03.com

killall named 2>/dev/null || true
named -c /etc/bind/named.conf


# ============================================================
# [PRAB]
# Verifikasi
# ============================================================

# dig @10.65.2.3 k-03.com A
# dig @10.65.2.3 k-03.com SOA +short


# ============================================================
# [TEDD]
# Install BIND dan konfigurasi DNS Slave
# ============================================================

apk update
apk add bind bind-tools

mkdir -p /var/bind/slaves
chown named:named /var/bind/slaves 2>/dev/null || true

cat > /etc/bind/named.conf <<'CONF'
options {
    directory "/var/bind";

    listen-on { any; };
    listen-on-v6 { none; };

    allow-query { any; };

    recursion yes;
    dnssec-validation no;

    forwarders {
        192.168.122.1;
    };
};

zone "k-03.com" {
    type slave;
    masters { 10.65.2.3; };
    file "slaves/db.k-03.com";
};
CONF


# ============================================================
# [TEDD]
# Validasi dan menjalankan DNS Slave
# ============================================================

named-checkconf

killall named 2>/dev/null || true
named -c /etc/bind/named.conf


# ============================================================
# [TEDD]
# Verifikasi
# ============================================================

# dig @10.65.2.2 k-03.com A
# dig @10.65.2.2 k-03.com SOA +short

# AXFR dari TEDD menuju PRAB:
# dig @10.65.2.3 k-03.com AXFR


# ============================================================
# [CLIENT / NODE NON-ROUTER]
# Konfigurasi resolver internal
# ============================================================

cat > /etc/resolv.conf <<'EOF'
nameserver 10.65.2.3
nameserver 10.65.2.2
nameserver 192.168.122.1
EOF


# ============================================================
# [CLIENT]
# Verifikasi resolusi
# ============================================================

# host prab.k-03.com
# host tedd.k-03.com

# ping -c 2 prab.k-03.com
# ping -c 2 tedd.k-03.com
# ping -c 2 k-03.com

# Pengujian DNS forwarder:
# ping -c 2 google.com


# ============================================================
# HASIL YANG DIHARAPKAN
# ============================================================

# PRAB:
# DNS Master pada 10.65.2.3
#
# TEDD:
# DNS Slave pada 10.65.2.2
#
# k-03.com:
# 10.65.5.2
#
# PRAB dan TEDD harus menjawab zona k-03.com
# secara authoritative.
#
# Client menggunakan:
# 10.65.2.3
# 10.65.2.2
# 192.168.122.1
#
# Resolusi domain internal dan domain eksternal
# harus berhasil.
