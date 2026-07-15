# VU Meter LCD — Mac (Intel/Hackintosh) Sürümü

Thermalright Trofeo Vision LCD paneli için ses görselleştirme + sistem monitörü.
USB üzerinden doğrudan panele yazar (trcc gerekmez).

## Gereksinimler

- **Intel tabanlı Mac** (Hackintosh dahil)
- **Thermalright Trofeo Vision LCD** paneli (USB 0416:5408)
- macOS + Xcode Command Line Tools (`xcode-select --install`)
- Homebrew (https://brew.sh)

### Opsiyonel (daha fazla sensör için)
- **Intel Power Gadget** — 24 çekirdek ısı haritası (sayfa 3) için.
  https://www.intel.com/content/www/us/en/developer/articles/tool/power-gadget.html
  Kurulu değilse diğer her şey yine çalışır, sadece çekirdek ısı haritası olmaz.

## Kurulum

1. Bu klasördeki **`kur.command`** dosyasına **çift tıkla**.
   - Homebrew paketlerini kurar (cava, libusb)
   - Python kütüphanelerini kurar (pygame, PyQt5, numpy, psutil, pyusb)
   - C sensör araçlarını derler (smc_read, gpu_read, disk_read, ipg_read)
   - İlk çift tıklamada macOS "geliştirici doğrulanamadı" derse:
     Sağ tık → Aç → Aç (bir kez), ya da Sistem Ayarları → Gizlilik ve Güvenlik → "Yine de Aç".

2. **Paneli tak** (USB).

3. **`baslat.command`** dosyasına **çift tıkla** — panel açılır.

## Kullanım

- **Menü çubuğu ikonu** (sağ üst) → mod değiştir, parlaklık, sistem monitörü sayfaları
- Modlar: Spektrum, LED Spektrum, VU Metre, Ölçüm Paneli, Sistem Monitörü
- **Sistem Monitörü** 3 sayfa:
  - Sensörler (CPU/GPU/fan/RAM/voltaj gauge'ları)
  - Disk Sıcaklıkları (tüm NVMe + SATA diskler)
  - Çekirdek Isı Haritası (24 çekirdek, Intel Power Gadget gerekir)

## Ses kaynağı

Uygulama, sistemin **varsayılan ses çıkış aygıtını** otomatik bulur ve onun sesini
görselleştirir. Ekstra ayar gerekmez. (Farklı bir kaynak istersen `native_proto_mac.py`
içindeki `_detect_mac_audio_source` fonksiyonuna bak.)

## Sorun giderme

- **Panel açılmıyor / logo takılı:** USB'yi çıkar, 10 sn bekle, tekrar tak. Sonra `baslat.command`.
- **Barlar oynamıyor:** Ses çıkışını kontrol et (sistem sesi bir aygıttan çalıyor olmalı).
  cava kurulu mu: `brew list cava`.
- **Çekirdek ısı haritası boş:** Intel Power Gadget kurulu değil (opsiyonel).
- **Bazı sensörler "--":** O donanımda o sensör yok (örn. GPU bellek sıcaklığı çoğu kartta yok).
- **"clang bulunamadı":** `xcode-select --install`

## Notlar

- Sensör okuma araçları (C) her donanıma göre farklı değer döndürür; olmayan sensörler
  panelde "--" görünür.
- Uygulama tamamen yerel çalışır, internet yalnızca hava sıcaklığı için (opsiyonel) kullanılır.
