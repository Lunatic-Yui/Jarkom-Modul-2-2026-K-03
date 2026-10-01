#!/bin/sh

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

ROLE="${1:-$(hostname)}"
case "$ROLE" in obladi|desmond) ROLE=vault ;; oblada|molly) ROLE=core ;; esac

case "$ROLE" in
vault)
    enable_mod() {
        if grep -rqE "^[[:space:]]*LoadModule $1 " /etc/apache2/; then return; fi
        if grep -qE "^#[[:space:]]*LoadModule $1 " /etc/apache2/httpd.conf; then
            sed -i -E "s|^#[[:space:]]*(LoadModule $1 .*)|\1|" /etc/apache2/httpd.conf
        else
            echo "LoadModule $1 modules/$2" >> /etc/apache2/conf.d/00-modules-mesh.conf
        fi
    }
    enable_mod remoteip_module mod_remoteip.so

    cat > /etc/apache2/conf.d/realip.conf <<'EOF'
RemoteIPHeader X-Real-IP
RemoteIPInternalProxy 10.65.4.0/24 10.65.5.0/24
EOF

    sed -i 's/^\([[:space:]]*LogFormat "\)%h /\1%a /' /etc/apache2/httpd.conf

    httpd -t || exit 1
    killall httpd 2>/dev/null
    sleep 1
    rm -f /run/apache2/httpd.pid
    mkdir -p /run/apache2
    httpd
    echo
    echo "Selesai (vault). client: curl http://www.k-03.com/"
    echo "Cek: tail /var/log/apache2/access.log"
    ;;

core)
    cat > /etc/nginx/http.d/realip.conf <<'EOF'
set_real_ip_from 10.65.4.0/24;
set_real_ip_from 10.65.5.0/24;
real_ip_header X-Real-IP;
EOF

    nginx -t || exit 1
    nginx -s reload 2>/dev/null || { mkdir -p /run/nginx; nginx; }
    echo
    echo "Selesai. client: curl http://static.k-03.com/"
    echo "Cek: tail /var/log/nginx/access.log"
    ;;

*)
    exit 1
    ;;
esac
