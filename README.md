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
    address 10.65.1.1
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

