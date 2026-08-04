# NCT6687D — 9 Fan Okuma (MSI MEG Z890 GODLIKE / MS-7E21)

Debian 13 (trixie) sıfır kurulumda anakart fanlarının **hepsini** okunur hale getirmek için
izlenen yol. Çekirdeğin kendi `nct6687` sürücüsü bu kartta yalnızca 3 fan veriyor
(CPU, Pump, System #1); geri kalanlar 0 RPM görünüyor.

Sonuç: **9 fan** okunur hale gelir → CPU Fan, Pump Fan, Pump Fan #2, System Fan #1–6.

---

## Sorunun kökü

Kart MSI **MEG Z890 GODLIKE (MS-7E21)**, çip **Nuvoton NCT6687D-M** (NCT6687DR ailesi).

İki ayrı mesele var:

1. **Yanlış register haritası.** Fred78290/nct6687d sürücüsünde iki fan yapılandırması var:
   - `default` → SYS_FAN registerları `0x144 / 0x146 / 0x148 …`
   - `msi_alt1` → SYS_FAN registerları `0x15E / 0x15C / 0x15A …`

   Z890 kartları `msi_alt1` ister, ama seçim DMI kart adı listesiyle yapılıyor ve
   **MEG Z890 GODLIKE listede yok** → `default` seçiliyor → SYS fanlar 0 RPM.

2. **İkinci pompa kanalı yok.** Sürücüde `NCT6687_NUM_REG_FAN 8` ve tabloda tek "Pump Fan"
   var. Bu kartta iki pompa başlığı var (BIOS: PUMP_SYS Fan 1 / 2).
   `msi_alt1` haritasında `0x144` boşta kalıyor ve **ikinci pompa oradan okunuyor**.

Doğrulama: `dmesg` satırı hangi yapılandırmanın seçildiğini söyler.

```
nct6687 …: active fan config=msi_alt1, SYS_FAN reg_rpm=0x015E/0x015C/0x015A
```

`config=default` yazıyorsa DMI eşleşmesi tutmamış demektir.

---

## Kurulum (sıfır sistemde sırayla)

### 1) Gerekli paketler

```
sudo apt update
sudo apt install -y dkms git build-essential lm-sensors linux-headers-$(uname -r)
```

### 2) Kaynağı al

```
cd /tmp
git clone https://github.com/Fred78290/nct6687d
cd nct6687d
```

### 3) Kart adını doğrula

```
sudo dmidecode -s baseboard-product-name
```

Beklenen çıktı: `MEG Z890 GODLIKE (MS-7E21)`

### 4) İki yamayı uygula

**(a) Kartı `msi_alt1` listesine ekle** — `MEG Z890 ACE (MS-7E22)` satırının hemen üstüne:

```
cd /tmp/nct6687d
python3 - << 'PYEOF'
lines = open('nct6687.c').readlines()
for i, l in enumerate(lines):
    if 'MEG Z890 ACE (MS-7E22)' in l:
        ind = l[:len(l) - len(l.lstrip())]
        lines.insert(i, ind + '{.matches = {DMI_MATCH(DMI_BOARD_NAME, "MEG Z890 GODLIKE (MS-7E21)")}},\n')
        break
open('nct6687.c','w').writelines(lines)
print("OK: GODLIKE listeye eklendi")
PYEOF
```

**(b) 9. kanalı (ikinci pompa) ekle** — kanal sayısını 9 yap, iki tabloya da satır ekle:

```
cd /tmp/nct6687d
python3 - << 'PYEOF'
src = open('nct6687.c').read()
src = src.replace('#define NCT6687_NUM_REG_FAN 8', '#define NCT6687_NUM_REG_FAN 9', 1)
open('nct6687.c','w').write(src)

lines = open('nct6687.c').readlines()

# msi_alt tablosu: 0x15E (System Fan #1) satirinin ustune Pump Fan #2
for i, l in enumerate(lines):
    if '0x15E' in l and 'System Fan #1' in l:
        ind = l[:len(l) - len(l.lstrip())]
        lines.insert(i, ind + '{.reg_rpm = 0x144, .reg_pwm = 0x162, .reg_pwm_write = 0xA2A, .label = "Pump Fan #2"},\n')
        break

# default tablo: dizi boyutu tutsun diye 9. kanal dolgusu
for i, l in enumerate(lines):
    if '0x14E' in l and 'System Fan #6' in l:
        ind = l[:len(l) - len(l.lstrip())]
        lines.insert(i + 1, ind + '{.reg_rpm = 0x150, .reg_pwm = 0x168, .reg_pwm_write = 0xA30, .label = "Fan #9"},\n')
        break

open('nct6687.c','w').writelines(lines)
print("OK: 9. kanal eklendi")
PYEOF
```

Kontrol:

```
grep -n "Z890 GODLIKE\|Pump Fan #2\|Fan #9\|NUM_REG_FAN 9" nct6687.c
```

### 5) DKMS ile kur

`make deb` yolu "already installed" hatası verebiliyor; doğrudan DKMS daha sorunsuz:

```
sudo rm -rf /usr/src/nct6687d-99.0.1
sudo cp -r /tmp/nct6687d /usr/src/nct6687d-99.0.1
sudo sed -i 's/^PACKAGE_VERSION=.*/PACKAGE_VERSION="99.0.1"/' /usr/src/nct6687d-99.0.1/dkms.conf
sudo dkms add nct6687d/99.0.1
sudo dkms install nct6687d/99.0.1 --force
```

### 6) Modülü yenile ve doğrula

```
sudo modprobe -r nct6687
sudo modprobe nct6687
sleep 3
sudo dmesg | grep -i nct6687 | tail -3
sensors nct6687-isa-0a20 | grep -i fan
```

Beklenen:

```
CPU Fan:       1840 RPM
Pump Fan:      2547 RPM
Pump Fan #2:   2836 RPM
System Fan #1: 1479 RPM
System Fan #2: 1512 RPM
System Fan #3: 1497 RPM
System Fan #4:  490 RPM
System Fan #5:  471 RPM
System Fan #6: 2403 RPM
```

### 7) Açılışta otomatik yükle

```
echo "nct6687" | sudo tee /etc/modules-load.d/nct6687.conf
```

---

## Fan eşleşmesi (BIOS ↔ Linux ↔ macOS)

| BIOS başlığı   | Linux etiketi   | macOS SMC | Örnek RPM |
|----------------|-----------------|-----------|-----------|
| CPU Fan 1      | CPU Fan         | F0Ac      | 1840      |
| PUMP_SYS Fan 2 | Pump Fan        | F2Ac      | 2547      |
| PUMP_SYS Fan 1 | Pump Fan #2     | F1Ac      | 2836      |
| SYS Fan 1      | System Fan #1   | F3Ac      | 1479      |
| SYS Fan 2      | System Fan #2   | F4Ac      | 1512      |
| SYS Fan 3      | System Fan #3   | F5Ac      | 1497      |
| SYS Fan 4      | System Fan #4   | F6Ac      | 490       |
| SYS Fan 5      | System Fan #5   | F7Ac      | 471       |
| SYS Fan 6      | System Fan #6   | F8Ac      | 2403      |

GPU fanı ayrı gelir: Linux'ta `amdgpu` hwmon üzerinden doğrudan; macOS'ta `navi21_fand`
servisinin `/tmp/navi21fan.json` çıktısından.

---

## Çekirdek güncellemesinden sonra

DKMS modülü otomatik yeniden derler. Derlemezse:

```
sudo dkms install nct6687d/99.0.1 -k $(uname -r) --force
```

Sürücünün yeni sürümü çıkarsa yamalar tekrar uygulanmalı (upstream'e kabul edilene kadar).

---

## Upstream'e katkı

İki değişiklik de genel fayda sağlıyor, PR olarak gönderilebilir:

1. `MEG Z890 GODLIKE (MS-7E21)` kartının `nct6687_msi_alt_boards[]` listesine eklenmesi —
   düşük riskli, tek satır, doğrudan kabul edilebilir.

2. 9. fan kanalı (ikinci pompa) — bu daha dikkatli sunulmalı. `0x144` adresi `default`
   haritada System Fan #1 olarak kullanılıyor; yalnızca `msi_alt1` haritasında boşta.
   Bu yüzden kanal sayısını global olarak 9 yapmak yerine, yapılandırma başına kanal
   sayısı tutmak daha temiz bir çözüm olur. PR'da bu gerekçeyle sunulmalı.

Depo: https://github.com/Fred78290/nct6687d

---

## Notlar

- `msi_fan_brute_force=1` modül parametresi fan **kontrolü** (PWM yazma) içindir,
  okuma için gerekmez.
- Kart adı `dmidecode` çıktısıyla birebir eşleşmeli; MSI aynı modelin farklı
  revizyonlarında farklı MS-xxxx kodu kullanabiliyor.
- `sensors-detect` çalıştırmaya gerek yok; modül ISA üzerinden doğrudan bulunuyor.
