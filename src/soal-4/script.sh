#!/bin/sh

# ============================================================
# SOAL 4
# Authoritative DNS Master-Slave
# Domain : k-03.com
#
# PRAB : 10.65.2.3 -> DNS Master
# TEDD : 10.65.2.2 -> DNS Slave
# PENNY: 10.65.5.2 -> Apex k-03.com
# ============================================================


# ============================================================
# [PRAB]
# Install BIND dan konfigurasi DNS Master
# ============================================================

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

named-checkconf
named-checkzone k-03.com /var/bind/db.k-03.com

killall named 2>/dev/null || true
named -c /etc/bind/named.conf


# ============================================================
# [TEDD]
# Install BIND dan konfigurasi DNS Slave
# Jalankan bagian ini pada node TEDD
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

named-checkconf

killall named 2>/dev/null || true
named -c /etc/bind/named.conf


# ============================================================
# [SEMUA NODE NON-ROUTER]
# Resolver setelah DNS internal aktif
# ============================================================

cat > /etc/resolv.conf <<'EOF'
nameserver 10.65.2.3
nameserver 10.65.2.2
nameserver 192.168.122.1
EOF


# ============================================================
# [VERIFIKASI]
# ============================================================

# Dari PRAB:
# dig @10.65.2.3 k-03.com A
# dig @10.65.2.3 prab.k-03.com A

# Dari TEDD:
# dig @10.65.2.2 k-03.com A
# dig @10.65.2.2 tedd.k-03.com A
# dig @10.65.2.2 k-03.com SOA +short

# Dari client:
# ping -c 1 prab.k-03.com
# ping -c 1 tedd.k-03.com
# ping -c 1 k-03.com
# ping -c 1 google.com
