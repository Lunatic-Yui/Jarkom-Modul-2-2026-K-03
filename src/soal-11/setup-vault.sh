#!/bin/sh
# for obladi and desmond script

[ "$(id -u)" = "0" ] || { echo "Jalankan sebagai root"; exit 1; }

echo 'LogFormat "%{Host}i %{X-Real-IP}i" hdr' > /etc/apache2/conf.d/hdr.conf
echo 'CustomLog /var/log/apache2/hdr.log hdr' >> /etc/apache2/conf.d/hdr.conf

if httpd -t; then
    killall httpd 2>/dev/null
    sleep 1
    rm -f /run/apache2/httpd.pid
    httpd
else
    echo "Config Apache error, httpd tidak di-restart"; exit 1
fi

echo
echo "Selesai. Dari client (alpha) jalankan:  curl http://www.k-03.com/"
echo "Lalu di node ini:  tail /var/log/apache2/hdr.log"
echo "Harus muncul:  www.k-03.com <IP client>   (bukan IP penny)"
