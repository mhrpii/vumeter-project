# Debian 13 Sıfır Kurulum — VU Meter Tam Kurulum Notları

MSI MEG Z890 GODLIKE (MS-7E21) + RX 6900 XT + Scarlett Solo 4th Gen için,
Debian 13 (trixie) KDE/Wayland ortamında sıfırdan kurulum adımları.

`.deb` paketleri (`vumeter-lcd-native`, `vumeter-desktop`) bağımlılıkların çoğunu
ve udev kurallarını kendi kurar. Bu belge, paketin **yapamadığı** manuel adımları
içerir.

---

## 1. Fan sürücüsü (9 fan için ZORUNLU)

Çekirdeğin kendi `nct6687` sürücüsü bu kartta yalnızca 3 fan verir.
Ayrıntılı gerekçe ve yamalar: `NCT6687D_9FAN_KURULUM.md`

Özet:

```
sudo apt install -y dkms git build-essential linux-headers-$(uname -r)
cd /tmp && git clone https://github.com/Fred78290/nct6687d && cd nct6687d
```

İki yama uygula (kart adını `msi_alt1` listesine ekle + 9. kanalı aç), sonra:

```
sudo rm -rf /usr/src/nct6687d-99.0.1
sudo cp -r /tmp/nct6687d /usr/src/nct6687d-99.0.1
sudo sed -i 's/^PACKAGE_VERSION=.*/PACKAGE_VERSION="99.0.1"/' /usr/src/nct6687d-99.0.1/dkms.conf
sudo dkms add nct6687d/99.0.1
sudo dkms install nct6687d/99.0.1 --force
sudo modprobe -r nct6687 && sudo modprobe nct6687
echo "nct6687" | sudo tee /etc/modules-load.d/nct6687.conf
```

Doğrulama — 9 satır gelmeli:

```
sensors nct6687-isa-0a20 | grep -i fan
```

> Upstream'e iki PR gönderildi (`mhrpii/nct6687d`). Kabul edilirse bu adım
> gereksiz hale gelir.

---

## 2. Disk doluluk oranları

Doluluk yalnızca **bağlı** birimler için okunabilir. Sıcaklık ise bağlı olmasa
da okunur (nvme + drivetemp hwmon).

Gerekli araçlar (`.deb` bunları `Recommends` olarak önerir):

```
sudo apt install -y exfatprogs hfsprogs ntfs-3g
```

Bağlama noktaları ve kalıcı bağlama:

```
sudo mkdir -p /mnt/disk_{minik500,serender,minik1,windows,kioxia}

sudo tee -a /etc/fstab > /dev/null << 'EOF'

# VU Meter disk doluluk okuma (salt okunur)
/dev/sdb2        /mnt/disk_minik500  exfat    ro,nofail,x-systemd.device-timeout=5  0 0
/dev/sdc2        /mnt/disk_serender  hfsplus  ro,nofail,x-systemd.device-timeout=5  0 0
/dev/sdd2        /mnt/disk_minik1    hfsplus  ro,nofail,x-systemd.device-timeout=5  0 0
/dev/nvme3n1p3   /mnt/disk_windows   ntfs-3g  ro,nofail,x-systemd.device-timeout=5  0 0
/dev/nvme4n1p2   /mnt/disk_kioxia    hfsplus  ro,nofail,x-systemd.device-timeout=5  0 0
EOF

sudo systemctl daemon-reload
sudo mount -a
```

> **Aygıt adları değişebilir.** Önce `lsblk -o NAME,SIZE,FSTYPE,LABEL` ile kontrol et.
> `nofail` sayesinde disk yoksa sistem yine açılır.

**APFS bölümler okunamaz.** İki macOS diski (`nvme0n1p2`, `nvme2n1p2`) Linux'ta
bağlanamaz; sıcaklıkları görünür, doluluk oranları boş kalır. Bu bir eksiklik
değil, APFS'in Linux'ta güvenilir sürücüsü yok.

---

## 3. Sensör izinleri (paket otomatik yapar)

`.deb` kurulumu şunları kendisi ayarlar; elle kurulumda gerekir:

```
# CPU gücü (RAPL enerji sayacı root'a kapalı gelir)
echo 'SUBSYSTEM=="powercap", ACTION=="add|change", RUN+="/bin/chmod 0444 /sys%p/energy_uj"' \
  | sudo tee /etc/udev/rules.d/99-rapl-read.rules
sudo chmod 0444 /sys/class/powercap/intel-rapl:0/energy_uj

# SATA disk sıcaklıkları
echo "drivetemp" | sudo tee /etc/modules-load.d/drivetemp.conf
sudo modprobe drivetemp

# LCD panel USB erişimi (root gerekmesin)
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0416", ATTRS{idProduct}=="5408", MODE="0666", TAG+="uaccess"' \
  | sudo tee /etc/udev/rules.d/99-trcc-panel.rules

sudo udevadm control --reload-rules
```

Panel takılıysa **bir kez çıkarıp tak** — udev kuralı yeni takılan aygıta uygulanır.

---

## 4. KDE pencere kuralı — sistem monitörü konumu

Wayland, uygulamaların pencere konumu belirlemesine izin vermez. pygame ile açılan
sistem monitörü penceresi bu yüzden ekran ortasında açılır. (Kontrol penceresi Qt
olduğu için kendi konumunu ayarlayabiliyor, ona gerek yok.)

Çözüm — `~/.config/kwinrulesrc` dosyasına kural ekle:

```
cat > ~/.config/kwinrulesrc << 'EOF'
[02e504e0-3bcf-4c99-8712-486d0061e83f]
Description=Sistem Monitoru sag alt
position=2400,1500
positionrule=3
title=Sistem Monitoru
titlematch=1
wmclass=vumeter_linux.py
wmclasscomplete=false
wmclassmatch=1

[General]
count=1
rules=02e504e0-3bcf-4c99-8712-486d0061e83f
EOF

qdbus6 org.kde.KWin /KWin reconfigure
```

Önemli ayrıntılar:

- `title=Sistem Monitoru` — pencere **başlığı** (Sistem Ayarları arayüzünde bu
  alanı "Pencere sınıfı" yerine "Pencere başlığı"na yazmak gerekiyor; karıştırılırsa
  kural hiç eşleşmez).
- `wmclass=vumeter_linux.py` — pencere sınıfı. Süreç `vumeter_linux.py --sysmon`
  olarak açıldığı için sınıf ana uygulamayla aynıdır.
- `position=2400,1500` — 3840×2160 ekran için. Kendi çözünürlüğüne göre ayarla.

Gerçek başlık/sınıfı öğrenmek için (pencere açıkken çalıştır, imleç değişince
hedef pencereye tıkla):

```
qdbus6 org.kde.KWin /KWin queryWindowInfo | grep -iE "caption|resourceClass"
```

---

## 5. Ses kaynağı (cava)

Uygulama Scarlett'in monitor kaynağını **profil bağımsız** bulur:
`pro-audio` profilinde `pro-output-0.monitor`, HiFi profilinde `Line1__sink.monitor`.

Bar gelmiyorsa kontrol sırası:

```
pactl get-default-sink                    # varsayilan cikis Scarlett mi
pactl list short sinks | grep -i scarlett # RUNNING mi SUSPENDED mi
grep -E "source|method" ~/.config/cava/config_native
```

`SUSPENDED` ise o çıkıştan ses akmıyor demektir — müzik başka bir aygıta gidiyordur
ya da ses kapalıdır.

> Not: Sistem monitöründeki "Ses: %100" göstergesi PipeWire'ın **yazılım**
> seviyesidir. Scarlett pro-audio profilinde seviye donanımdan (fiziksel düğme)
> ayarlanır, o yüzden yazılım tarafı hep %100 görünür. Hata değildir.

---

## 6. Kurulum sonrası hızlı doğrulama

```
sensors nct6687-isa-0a20 | grep -ci fan        # 9 olmali
cat /sys/class/powercap/intel-rapl:0/energy_uj # sayi donmeli (izin)
df -h | grep /mnt/disk                          # bagli diskler
lsusb | grep 0416:5408                          # LCD panel
```

Python tarafı:

```
cd /opt/vumeter-lcd-native
python3 -c "
import sys, time; sys.path.insert(0,'.')
import sysmon
m = sysmon.SysMonitor(); time.sleep(4); d = m.snapshot()
print('fan sayisi:', len([k for k in d if k.startswith('fan_') and d[k]]))
print('cpu_power:', d.get('cpu_power'))
print('cpu_voltage:', d.get('cpu_voltage'))
print('disk sayisi:', len(d.get('disks') or []))
print('cekirdek:', (d.get('ipg') or {}).get('num_cores'))
m.stop()
"
```

Beklenen: 9 fan, cpu_power dolu, cpu_voltage dolu, 9 disk, 24 çekirdek.

---

## Bilinen sınırlar

| Konu | Durum |
|---|---|
| APFS disk doluluk | Linux'ta okunamaz (sürücü yok) |
| Sistem monitörü pencere konumu | Wayland kısıtı → KDE kuralıyla çözülür |
| GPU fan RPM | Linux'ta amdgpu hwmon'dan anlık gelir (macOS'ta ek servis gerekiyordu) |
| Çekirdek numaraları | coretemp fiziksel numaraları seyrek (0,4,8,28…), C0'dan sıralı yeniden numaralandırılır |
