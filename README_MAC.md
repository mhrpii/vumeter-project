# VU Meter LCD — Mac (Intel/Hackintosh) Surumu

Thermalright Trofeo Vision LCD paneli icin ses gorsellestirme + sistem monitoru.
USB uzerinden dogrudan panele yazar (trcc gerekmez).

## Gereksinimler

- Intel tabanli Mac (Hackintosh dahil)
- Thermalright Trofeo Vision LCD paneli (USB 0416:5408)
- macOS + Xcode Command Line Tools (`xcode-select --install`)
- Homebrew (https://brew.sh)

### Opsiyonel
- Intel Power Gadget — 24 cekirdek isi haritasi (sayfa 3) icin.
  https://www.intel.com/content/www/us/en/developer/articles/tool/power-gadget.html
  Yoksa diger her sey calisir, sadece cekirdek isi haritasi olmaz.

## Kurulum (modern macOS — 13 ve ustu)

1. `kur.command` dosyasina cift tikla:
   - cava + libusb (Homebrew)
   - Python kutuphaneleri (pygame, PyQt5, numpy, psutil, pyusb)
   - C sensor araclari (smc_read, gpu_read, disk_read, ipg_read)
   - /Applications/VU Meter LCD.app olusturur (Launchpad/Spotlight'ta gorunur)
   - Ilk acilista "gelistirici dogrulanamadi" derse: Sag tik -> Ac -> Ac.
2. Ses kurulumu (asagidaki bolum) — BlackHole + Multi-Output.
3. Paneli tak, uygulamaya cift tikla.

## Ses kurulumu (TUM Mac'lerde gerekli olabilir)

macOS, hoparlorden calan sesi uygulamalarin dogrudan yakalamasina izin vermez.
Sesi cava'ya ulastirmak icin BlackHole (ucretsiz sanal ses aygiti) gerekir.

1. BlackHole 2ch indir + kur (.pkg installer):
   - https://existential.audio/blackhole/ , ya da
   - https://github.com/ExistentialAudio/BlackHole/releases (Assets -> BlackHole2ch...pkg)
2. Audio MIDI Setup ac (Uygulamalar -> Izlenceler):
   - Sol alt + -> Create Multi-Output Device
   - Icinde Built-in Output (ya da hoparlor/arayuz) + BlackHole 2ch isaretle
   - (Built-in Output satirinda "Drift Correction" isaretlemek senkron icin iyi)
3. Sistem ses cikisini "Multi-Output Device" yap
   (menu cubugu ses ikonu ya da Sistem Ayarlari -> Ses -> Cikis).
   Boylece ses hem hoparlorden duyulur hem BlackHole'a gider; cava BlackHole'u dinler.
4. Uygulama cava icin otomatik olarak BlackHole'u secer (Multi-Output'u degil).

NOT: Ses arayuzu (Focusrite/Scarlett vb.) kullaniyorsan BlackHole gerekmeyebilir —
uygulama Scarlett/Focusrite'i otomatik bulur ve dogrudan dinler.

## macOS 12 (Monterey) ve oncesi — cava elle kurulum

Eski macOS'ta Homebrew "Tier 3" kabul edilir; `brew install cava` cogu zaman gcc'yi
kaynaktan derlemeye calisip BASARISIZ olur. Cozum: cava'yi calisan bir Mac'ten
kopyalamak (ayni mimari — Intel/x86_64).

Calisan bir Intel Mac'ten (cava kurulu):
1. cava binary'sini bul: `which cava` (or. /usr/local/bin/cava) ve
   /usr/local/Cellar/cava/... klasorunu kopyala.
2. Bagimli dylib'leri bul: `otool -L /usr/local/bin/cava`
   Sistem disi olanlar (tasinmasi gerekenler) genelde:
   - /usr/local/opt/portaudio/lib/libportaudio.2.dylib
   - /usr/local/opt/fftw/lib/libfftw3.3.dylib
   - /usr/local/opt/iniparser/lib/libiniparser.4.dylib
3. Bu dosyalari hedef Mac'e tasi (AirDrop/USB) ve ayni yollara koy:
   mkdir -p /usr/local/opt/portaudio/lib /usr/local/opt/fftw/lib /usr/local/opt/iniparser/lib
   cp libportaudio.2.dylib  /usr/local/opt/portaudio/lib/
   cp libfftw3.3.dylib      /usr/local/opt/fftw/lib/
   cp libiniparser.4.dylib  /usr/local/opt/iniparser/lib/
   (cava binary'sini de /usr/local/bin/ ve Cellar'a koy)
4. Test: `cava -v` -> surum yazmali (dylib eksikse hata verir, o dylib'i de tasi).

Sonra yukaridaki "Ses kurulumu" (BlackHole + Multi-Output) adimlarini izle.

## Kullanim

- Menu cubugu ikonu -> mod degistir, parlaklik, sistem monitoru sayfalari
- Modlar: Spektrum, LED Spektrum, VU Metre, Olcum Paneli, Sistem Monitoru
- Sistem Monitoru 3 sayfa:
  - Sensorler (CPU/GPU/fan/RAM/voltaj)
  - Disk Sicakliklari (tum NVMe + SATA)
  - Cekirdek Isi Haritasi (24 cekirdek, Intel Power Gadget gerekir)

## Sorun giderme

- Barlar oynamiyor / "VINTAGE SES KONSOLU":
  - Sistem ses cikisi "Multi-Output Device" mi? (BlackHole'a ses gitmeli)
  - cava kurulu mu: `cava -v`
  - Uygulama BlackHole'u mu seciyor:
    python3 -c "import native_proto_mac as n; print(n._detect_mac_audio_source())"
    -> BlackHole 2ch (ya da Scarlett) olmali, Multi-Output Device DEGIL.
- Panel acilmiyor / logo takili: USB cikar, 10 sn bekle, tak. Tek kopya calistir
  (pkill -f native_proto ile eskiyi kapat).
- Cekirdek isi haritasi bos: Intel Power Gadget kurulu degil (opsiyonel).
- Bazi sensorler "--": O donanimda o sensor yok.
- Uygulama ikonu gorunmuyor (roket): macOS ikon onbellegi. killall Dock Finder,
  olmazsa reboot; ya da .app'i kopyalayip yeniden adlandir (onbellegi atlatir).
- "clang bulunamadi": xcode-select --install

## Notlar

- Sensor araclari (C) her donanima gore farkli deger dondurur; olmayan sensorler "--".
- Tamamen yerel calisir; internet yalnizca hava sicakligi icin (opsiyonel).
