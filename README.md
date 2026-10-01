# JARKOM-MODUL-2-2026-K-03

## Member

| Nama                      | NRP        | Pembagian Kerja |
| ------------------------- | ---------- | ---------- |
| Yovi Prayudya Rizky Ramadhani      | 5027251107 | No 1 - 3 & 11 - 20 |
| Dafa Ridho Zhafif  | 5027251129 | No 4 - 10 |

## Laporan

1. ![image](./assets/soal/soal-1.png)

Untuk modelnya seperti berikut:

![image](./assets/jawaban/model-soal-1.png)

dengan:
- Rootkit sebagai router
- Alpha, Beta, Gamma, Delta, Epsilon sebagai operator
- Abbey dan Penny sebagai gerbang penyaring
- Prab dan Tedd sebagai penjaga directory
- obladi, desmond, oblada, molly sebagai repositori

2. ![image](./assets/soal/soal-2.png)

Untuk configure pada router Rootkit adalah sebagai berikut

```
auto eth0
iface eth0 inet dhcp
    up sysctl -w net.ipv4.ip_forward=1
    up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE    

auto eth1
iface eth1 inet static
    address 10.65.2.1
    netmask 255.255.255.0
    echo "nameserver 8.8.8.8" > /etc/resolv.conf  

auto eth2
iface eth2 inet static
    address 10.65.4.1
    netmask 255.255.255.0
    echo "nameserver 8.8.8.8" > /etc/resolv.conf  

auto eth3
iface eth3 inet static
   address 10.65.5.1
   netmask 255.255.255.0
   echo "nameserver 8.8.8.8" > /etc/resolv.conf  

auto eth4
iface eth4 inet static
   address 10.65.6.1
   netmask 255.255.255.0
   echo "nameserver 8.8.8.8" > /etc/resolv.conf  

auto eth5
iface eth5 inet static
   address 10.65.7.1
   netmask 255.255.255.0
   echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

sesuai dengan [modul 1 Jarkom lab KCKS repository](https://github.com/lab-kcks/modul-komdat-jarkom-2026/tree/main/Modul%201) sebagai referensinya. Penjelasannya pada [github saya modul 1](https://github.com/Lunatic-Yui/Jarkom-Modul-1-2026-K-03)

3. ![image](./assets/soal/soal-3.png)

Untuk configurenya saya pakai modul 1 juga jadi seperti berikut

```cfg
auto eth0
iface eth0 inet static
   address 10.65.x.y
   netmask 255.255.255.0
   gateway 10.65.x.1
   up echo "nameserver 192.168.122.1" > /etc/resolv.conf
```

dengan x awalannya adalah switchnya dan y adalah device yang terkoneksi ke switch sedangkan `10.65.x.1` itu untuk gerbang ke switchnya. Nah agar persistensi, saya tambahkan `up echo "nameserver 192.168.122.1 > /etc/resolv.conf` agar tidak perlu ping ke google.com lagi. Hasilnya seperti berikut:

![image](./assets/jawaban/result-soal-3.png)

### 4. Konfigurasi Authoritative DNS Master dan Slave

Pada tahap ini, **Prab** dikonfigurasi sebagai authoritative DNS master untuk domain:

```text
k-03.com
```

sedangkan **Tedd** digunakan sebagai DNS slave.

IP yang digunakan:

```text
Prab : 10.65.2.3
Tedd : 10.65.2.2
Penny: 10.65.5.2
```

Pada Prab digunakan BIND sebagai DNS server. Konfigurasi utama zona dibuat dengan SOA yang menunjuk ke `prab.k-03.com`, serta NS record untuk Prab dan Tedd.

Contoh konfigurasi zona pada Prab:

```dns
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
```

Apex domain `k-03.com` diarahkan menuju Penny dengan IP `10.65.5.2`.

Pada Prab juga diaktifkan mekanisme `notify` dan `allow-transfer` agar perubahan zone dapat dikirimkan menuju Tedd:

```cfg
zone "k-03.com" {
    type master;
    file "db.k-03.com";

    notify yes;
    also-notify { 10.65.2.2; };
    allow-transfer { 10.65.2.2; };
};
```

Selain itu digunakan DNS forwarder:

```cfg
forwarders {
    192.168.122.1;
};
```

Pada Tedd, zona `k-03.com` dikonfigurasi sebagai slave:

```cfg
zone "k-03.com" {
    type slave;
    masters { 10.65.2.3; };
    file "slaves/db.k-03.com";
};
```

Resolver pada seluruh node non-router kemudian diubah menjadi:

```cfg
nameserver 10.65.2.3
nameserver 10.65.2.2
nameserver 192.168.122.1
```

Hasil verifikasi authoritative DNS slave pada Tedd:

![image](./assets/jawaban/result-soal-4-1.png)

TEDD berhasil berfungsi sebagai authoritative DNS slave untuk zona `k-03.com`. Hal tersebut terlihat dari flag `aa`, A record `k-03.com` yang mengarah ke Penny (`10.65.5.2`), serta SOA yang menunjuk Prab sebagai DNS master.

Pengujian resolusi DNS dari Alpha:

![image](./assets/jawaban/result-soal-4-2.png)

Client Alpha berhasil melakukan resolusi `prab.k-03.com`, `tedd.k-03.com`, dan `k-03.com`. Resolusi domain eksternal `google.com` juga berhasil, yang menunjukkan bahwa DNS internal dan forwarder telah berjalan dengan baik.

---

### 5. Konfigurasi Hostname dan A Record Seluruh Entitas

Setiap entitas kemudian diberikan hostname sesuai dengan nama node masing-masing dan dibuatkan A record pada domain `k-03.com`.

A record yang digunakan adalah:

```dns
rootkit IN  A       10.65.1.1

alpha   IN  A       10.65.6.2
beta    IN  A       10.65.6.3
gamma   IN  A       10.65.6.4

delta   IN  A       10.65.7.2
epsilon IN  A       10.65.7.3

prab    IN  A       10.65.2.3
tedd    IN  A       10.65.2.2

abbey   IN  A       10.65.4.2
penny   IN  A       10.65.5.2

obladi  IN  A       10.65.3.5
desmond IN  A       10.65.3.4
oblada  IN  A       10.65.3.3
molly   IN  A       10.65.3.2
```

Serial SOA dinaikkan menjadi:

```text
2026092902
```

Untuk Rootkit, hostname juga disesuaikan menjadi:

```bash
hostname rootkit
```

Hasil verifikasi A record melalui client Alpha:

![image](./assets/jawaban/result-soal-5.png)

Pengujian menunjukkan beberapa hostname seperti Alpha, Beta, Abbey, Penny, Oblada, dan Molly berhasil di-resolve ke alamat IP masing-masing. Hal ini menunjukkan A record pada zona `k-03.com` telah bekerja sesuai konfigurasi.

---

### 6. Verifikasi Zone Transfer Prab ke Tedd

Untuk memastikan Tedd mendapatkan salinan zone terbaru dari Prab, dilakukan pemeriksaan serial SOA pada kedua DNS server.

Hasilnya:

![image](./assets/jawaban/result-soal-6-1.png)

Prab dan Tedd memiliki serial SOA yang sama, yaitu:

```text
2026092902
```

Tedd juga berhasil menjawab record terbaru seperti:

```text
molly.k-03.com → 10.65.3.2
beta.k-03.com  → 10.65.6.3
```

Selain itu dilakukan pengujian AXFR dari Tedd menuju Prab:

![image](./assets/jawaban/result-soal-6-2.png)

Hasil AXFR menampilkan seluruh record dalam zone `k-03.com` dengan:

```text
XFR size: 19 records
```

Hal tersebut menunjukkan mekanisme zone transfer dari DNS master menuju DNS slave telah berjalan dengan baik.

---

### 7. Konfigurasi Record Vault, Core, WWW, dan Static

Selanjutnya dibuat record untuk merepresentasikan kelompok layanan web statis dan dinamis.

Untuk area Vault:

```dns
vault   IN  A       10.65.3.5
vault   IN  A       10.65.3.4
```

Dengan:

```text
10.65.3.5 → Obladi
10.65.3.4 → Desmond
```

Untuk area Core:

```dns
core    IN  A       10.65.3.3
core    IN  A       10.65.3.2
```

Dengan:

```text
10.65.3.3 → Oblada
10.65.3.2 → Molly
```

Kemudian dibuat CNAME:

```dns
www     IN  CNAME   penny.k-03.com.
static  IN  CNAME   abbey.k-03.com.
```

Sehingga:

```text
www.k-03.com    → penny.k-03.com
static.k-03.com → abbey.k-03.com
```

Serial zona kemudian dinaikkan menjadi:

```text
2026092903
```

Pengujian dilakukan dari dua client yang berbeda.

Pengujian dari Alpha:

![image](./assets/jawaban/result-soal-7-1.png)

Pengujian dari Delta:

![image](./assets/jawaban/result-soal-7-2.png)

Hasil dari Alpha maupun Delta menunjukkan bahwa `vault.k-03.com` berhasil mengarah ke Obladi dan Desmond, sedangkan `core.k-03.com` mengarah ke Oblada dan Molly. CNAME `www.k-03.com` juga berhasil mengarah ke Penny dan `static.k-03.com` ke Abbey. Hasil tersebut menunjukkan resolusi DNS konsisten dari dua jaringan client yang berbeda.

---

### 8. Konfigurasi Reverse DNS

Reverse DNS dikonfigurasi untuk jaringan tempat Abbey, Penny, area Vault, dan area Core berada.

Karena node-node tersebut berada pada beberapa subnet, dibuat tiga reverse zone:

```text
10.65.3.0/24 → 3.65.10.in-addr.arpa
10.65.4.0/24 → 4.65.10.in-addr.arpa
10.65.5.0/24 → 5.65.10.in-addr.arpa
```

PTR record yang digunakan:

```dns
10.65.4.2 → abbey.k-03.com.
10.65.5.2 → penny.k-03.com.

10.65.3.5 → vault.k-03.com.
10.65.3.4 → vault.k-03.com.

10.65.3.3 → core.k-03.com.
10.65.3.2 → core.k-03.com.
```

Contoh reverse zone untuk area Core dan Vault:

```dns
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
```

PRAB dikonfigurasi sebagai master dari ketiga reverse zone dan TEDD sebagai slave.

Hasil validasi reverse zone pada Prab:

![image](./assets/jawaban/result-soal-8-1.png)

Ketiga reverse zone berhasil dimuat dengan status `OK`, dan reverse lookup berhasil mengembalikan hostname Abbey, Penny, Vault, dan Core.

Selanjutnya dilakukan pengujian melalui Tedd:

![image](./assets/jawaban/result-soal-8-2.png)

Tedd berhasil menjawab reverse query dengan status `NOERROR` dan flag `aa`, sehingga dapat disimpulkan bahwa reverse zone telah berhasil ditransfer ke DNS slave dan dapat dijawab secara authoritative.

---

### 9. Web Statis pada Area Vault

Area Vault terdiri dari:

```text
Obladi  → 10.65.3.5
Desmond → 10.65.3.4
```

Kedua node menjalankan layanan web statis menggunakan Apache.

Pada masing-masing server dibuat direktori:

```text
/var/www/localhost/htdocs/arsip
```

Kemudian directory listing diaktifkan menggunakan:

```apache
<Directory "/var/www/localhost/htdocs/arsip">
    Options +Indexes
    AllowOverride None
    Require all granted
</Directory>
```

Pada Obladi dibuat beberapa file:

```text
dokumen-vault.txt
network-info.txt
obladi.txt
```

Pengujian dilakukan menggunakan hostname:

```bash
curl http://obladi.k-03.com/arsip/
```

Hasil:

![image](./assets/jawaban/result-soal-9-1.png)

Directory listing pada Obladi berhasil menampilkan seluruh file pada direktori `/arsip/`.

Pada Desmond dibuat:

```text
desmond.txt
dokumen-vault.txt
network-info.txt
```

Pengujian:

```bash
curl http://desmond.k-03.com/arsip/
```

Hasil:

![image](./assets/jawaban/result-soal-9-2.png)

Directory listing pada Desmond juga berhasil berjalan. Dengan demikian, kedua node area Vault mampu menyediakan layanan web statis melalui hostname masing-masing tanpa menggunakan alamat IP secara langsung.

---

### 10. Web Dinamis pada Area Core

Area Core terdiri dari:

```text
Oblada → 10.65.3.3
Molly  → 10.65.3.2
```

Kedua node dikonfigurasi menggunakan:

```text
Nginx
PHP 8.4
PHP-FPM
```

Aplikasi sederhana dibuat pada:

```text
/var/www/core/index.php
/var/www/core/profil.php
```

Halaman utama menampilkan halaman Beranda, sedangkan `profil.php` digunakan sebagai halaman Profil.

Nginx dikonfigurasi agar file PHP diproses melalui PHP-FPM:

```nginx
location ~ \.php$ {
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_pass 127.0.0.1:9000;
}
```

Selain itu diterapkan rewrite:

```nginx
rewrite ^/profil/?$ /profil.php last;
```

Sehingga halaman Profil dapat diakses menggunakan:

```text
/profil
```

tanpa perlu menambahkan ekstensi `.php`.

Pada saat pengujian ditemukan bahwa link GNS3 milik Oblada terhubung dari Switch3 menuju interface `eth1`. Oleh karena itu IP Oblada `10.65.3.3/24` dipasang pada `eth1` agar dapat berkomunikasi dengan jaringan area Core.

Pengujian akhir dilakukan dari client Alpha:

```bash
curl http://oblada.k-03.com/
curl http://oblada.k-03.com/profil

curl http://molly.k-03.com/
curl http://molly.k-03.com/profil
```

Hasil:

![image](./assets/jawaban/result-soal-10.png)

Pengujian menunjukkan bahwa Oblada dan Molly berhasil menjalankan layanan web dinamis menggunakan Nginx dan PHP-FPM. Halaman Beranda dan Profil dapat ditampilkan pada kedua server, serta identitas server masing-masing berhasil ditampilkan melalui PHP. Path `/profil` juga dapat diakses tanpa ekstensi `.php`, sehingga konfigurasi rewrite telah berjalan sesuai requirement.

11. Konfigurasikan Penny (menggunakan Apache) sebagai reverse proxy yang mengarah ke semua node di area vault (Obladi & Desmond). Sementara itu, konfigurasikan Abbey (menggunakan Nginx) sebagai reverse proxy menuju area core (Oblada & Molly). Pastikan kedua gerbang ini meneruskan identitas asli pengunjung ke server backend dengan melakukan forwarding header Host dan X-Real-IP. Buktikan bahwa Penny dan Abbey berhasil mendistribusikan lalu lintas dengan tepat.

Untuk scriptnya seperti berikut

[setup-abbey.sh](./src/soal-11/setup-abbey.sh)

[setup-penny.sh](./src/soal-11/setup-penny.sh)

Dan menambahkan ke obladi dan desmond dengan

```cfg
echo 'LogFormat "%{Host}i %{X-Real-IP}i" hdr' > /etc/apache2/conf.d/hdr.conf
echo 'CustomLog /var/log/apache2/hdr.log hdr' >> /etc/apache2/conf.d/hdr.conf
httpd -t && killall httpd 
httpd
```

pada configurasinya untuk prove. Hasilnya ketika kita melakukan

![image](./assets/jawaban/soal-11/curl-result.png)

maka di obladi:

![image](./assets/jawaban/soal-11/obladi-curl.png)

(ini sebelumnya saya test dulu dan berhasil ternyata) dan di desmond:

![image](./assets/jawaban/soal-11/desmond-curl.png)

