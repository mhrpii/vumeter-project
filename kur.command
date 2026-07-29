#!/bin/bash
#
# kur.command — VU Meter LCD Mac kurulum + Applications'a .app kur
#
cd "$(dirname "$0")" || exit 1


# --- DMG kontrolu: salt okunur birimden kurulum yapilamaz ---
if [[ "$(pwd)" == /Volumes/* ]] && [ ! -w "$(pwd)" ]; then
    echo ""
    echo "=================================================="
    echo "  HATA: DMG icinden calistiriyorsunuz!"
    echo ""
    echo "  Bu klasor salt okunur oldugu icin sensor araclari"
    echo "  derlenemez (disk isilari, fanlar calismaz)."
    echo ""
    echo "  YAPIN: Bu klasorun tamamini Masaustu'ne KOPYALAYIN,"
    echo "         sonra oradaki kur.command dosyasini calistirin."
    echo "=================================================="
    echo ""
    read -p "Kapatmak icin Enter..."
    exit 1
fi

echo "=================================================="
echo "  VU Meter LCD — Mac Kurulum"
echo "=================================================="
echo ""

# macOS surumu tespit (12 ve oncesi Homebrew Tier 3 - cava kurulamaz)
OSVER="$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)"
ESKI_MACOS=0
if [ -n "$OSVER" ] && [ "$OSVER" -le 12 ]; then
    ESKI_MACOS=1
    echo "[i] macOS $OSVER tespit edildi (eski surum)."
    echo "    Homebrew bu surumde cava'yi kaynaktan derleyemeyebilir."
    echo "    Sorun cikarsa README'deki 'macOS 12 elle kurulum' bolumune bak."
    echo ""
fi

# --- 1) Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
    echo "[!] Homebrew yok. Kur: https://brew.sh"
    read -p "Enter ile devam..."
else
    echo "[OK] Homebrew bulundu."
fi

# --- 2) cava + libusb ---
echo ""
echo "[*] cava + libusb kuruluyor..."
ARCH="$(uname -m)"
install_cava_from_deps() {
    # mac_deps/ icindeki hazir cava + dylib'leri yerine koy (Intel Mac icin)
    if [ ! -d "mac_deps" ] || [ ! -f "mac_deps/cava" ]; then
        return 1
    fi
    if [ "$ARCH" != "x86_64" ]; then
        echo "    [!] mac_deps Intel (x86_64) icin; bu makine $ARCH — kullanilamaz."
        return 1
    fi
    echo "    [*] mac_deps/ icinden hazir cava + kutuphaneler kuruluyor..."
    # dylib hedef klasorleri
    mkdir -p /usr/local/opt/portaudio/lib /usr/local/opt/fftw/lib /usr/local/opt/iniparser/lib 2>/dev/null
    cp mac_deps/libportaudio.2.dylib  /usr/local/opt/portaudio/lib/ 2>/dev/null
    cp mac_deps/libfftw3.3.dylib      /usr/local/opt/fftw/lib/      2>/dev/null
    cp mac_deps/libiniparser.4.dylib  /usr/local/opt/iniparser/lib/ 2>/dev/null
    # dylib'leri /usr/local/lib'e de koy (yedek arama yolu)
    cp mac_deps/*.dylib /usr/local/lib/ 2>/dev/null
    # cava binary
    cp mac_deps/cava /usr/local/bin/cava 2>/dev/null
    chmod +x /usr/local/bin/cava 2>/dev/null
    if /usr/local/bin/cava -v >/dev/null 2>&1; then
        echo "    [OK] cava mac_deps'ten kuruldu ($(cava -v 2>/dev/null | head -1))."
        return 0
    fi
    return 1
}

if command -v cava >/dev/null 2>&1 && cava -v >/dev/null 2>&1; then
    echo "[OK] cava zaten kurulu ($(command -v cava))."
elif install_cava_from_deps; then
    :   # mac_deps'ten kuruldu
elif command -v brew >/dev/null 2>&1; then
    echo "[*] cava brew ile deneniyor..."
    if ! brew install cava 2>/dev/null; then
        echo "[!] cava brew ile kurulamadi (eski macOS + gcc derleme sorunu olabilir)."
        echo "    mac_deps/ klasoru yoksa: README 'macOS 12 elle kurulum' bolumunu izle."
    fi
else
    echo "[!] cava kurulamadi (Homebrew yok, mac_deps yok)."
fi
command -v brew >/dev/null 2>&1 && { brew list libusb >/dev/null 2>&1 || brew install libusb 2>/dev/null; }

# --- 3) Ses yolu notu ---
echo ""
echo "[i] Ses: loopback ozellikli ses karti (ornek: Scarlett) varsa"
echo "    ek yazilim gerekmez - sistem cikisini o karta alin."
echo "    Loopback yoksa BlackHole gibi sanal aygit gerekir (README)."

# --- 4) Python kutuphaneleri ---
echo ""
echo "[*] Python kutuphaneleri kuruluyor..."
PYBIN="$(command -v python3)"
[ -z "$PYBIN" ] && { echo "[!] python3 yok: xcode-select --install"; read -p "Enter..."; }
"$PYBIN" -m pip install --user pygame PyQt5 numpy psutil pyusb Pillow 2>&1 | tail -2
echo "[OK] Python kutuphaneleri hazir."

# --- 5) C araclarini derle ---
echo ""
echo "[*] C sensor araclari derleniyor..."
compile() {
    if [ -f "$2" ]; then
        clang -O2 -o "$1" "$2" "${@:3}" 2>/dev/null \
            && echo "    [OK] $1" || echo "    [!] $1 derlenemedi"
    fi
}
compile smc_read  smc_read.c  -framework IOKit -framework CoreFoundation
compile gpu_read  gpu_read.c  -framework IOKit -framework CoreFoundation
compile disk_read disk_read.c -framework IOKit -framework CoreFoundation
if [ -d "/Library/Frameworks/IntelPowerGadget.framework" ]; then
    compile ipg_read ipg_read.c -F/Library/Frameworks -framework IntelPowerGadget
else
    echo "    [!] Intel Power Gadget yok — cekirdek isi haritasi calismaz (opsiyonel)."
fi
compile make_aggregate make_aggregate.c -framework CoreAudio -framework CoreFoundation
compile launcher_main launcher_main.c
# --- 6) .app olustur (kucuk C launcher + duz python dosyalari) ---
# PyInstaller BIRAKILDI: 123MB bundle LaunchServices dogrulamasinda ~45sn
# gecikiyordu. Kucuk launcher ile acilis aninda. Mikrofon izni de gerekmiyor
# (Scarlett loopback girisi TCC mikrofon kapsaminda degil - sahada dogrulandi).
echo ""
echo "[*] Launcher derleniyor..."
clang -fobjc-arc -o vu_launcher vu_launcher.m \
      -framework Foundation -framework AVFoundation 2>/dev/null \
  && echo "[OK] vu_launcher derlendi" || { echo "[!] launcher derlenemedi"; read -p "Enter..."; exit 1; }

echo "[*] Uygulama olusturuluyor..."
APP="/Applications/VU Meter LCD.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/app"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>VU Meter LCD</string>
    <key>CFBundleIdentifier</key><string>com.mhrpii.vumeterlcd</string>
    <key>CFBundleExecutable</key><string>vu_launcher</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>NSMicrophoneUsageDescription</key><string>VU Meter, ses kartindan gelen sesi gorsellestirmek icin ses girisini kullanir.</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

cp vu_launcher "$APP/Contents/MacOS/"
chmod +x "$APP/Contents/MacOS/vu_launcher"
cp *.py                                  "$APP/Contents/Resources/app/" 2>/dev/null
cp *.png                                 "$APP/Contents/Resources/app/" 2>/dev/null
cp smc_read gpu_read disk_read ipg_read mic_permission "$APP/Contents/Resources/app/" 2>/dev/null
echo "[OK] Uygulama kuruldu: $APP"


echo ""
echo "=================================================="
echo "  Kurulum tamamlandi!"
echo ""
echo "  - Launchpad/Spotlight'ta 'VU Meter LCD' ile acin"
echo "  - Ses: sistem cikisi loopback ozellikli ses kartinda olmali"
echo "  - Ses gelmezse: Sistem Ayarlari > Ses > Cikis kontrol edin"
echo "=================================================="
echo ""


read -p "Kapatmak icin Enter..."
