#!/bin/bash
# kur_masaustu.command — VU Meter MASAUSTU Mac kurulum ("VU Meter Masaustu.app")
# LCD panel GEREKMEZ - gorselleştirme pencerede calisir.
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
    echo "         sonra oradaki kur_masaustu.command dosyasini calistirin."
    echo "=================================================="
    echo ""
    read -p "Kapatmak icin Enter..."
    exit 1
fi

echo "=================================================="
echo "  VU METER MASAUSTU - Mac Kurulum"
echo "=================================================="

# --- 1) Python3 kontrol ---
if ! command -v python3 >/dev/null 2>&1; then
    echo "[!] python3 bulunamadi. Xcode Command Line Tools kurun:"
    echo "    xcode-select --install"
    read -p "Enter..."; exit 1
fi
echo "[OK] python3: $(python3 --version)"

# --- 2) Python paketleri ---
echo "[*] Python paketleri kontrol ediliyor (pygame, numpy, PyQt5, psutil)..."
python3 -m pip install --quiet --user pygame numpy PyQt5 psutil Pillow 2>/dev/null
echo "[OK] paketler hazir"

# --- 3) cava kontrol (mac_deps'ten offline kurulum destekli) ---
if ! command -v cava >/dev/null 2>&1 && [ ! -x /usr/local/bin/cava ]; then
    if [ -d "mac_deps" ] && [ -f "mac_deps/cava" ]; then
        echo "[*] cava mac_deps'ten kuruluyor..."
        sudo cp mac_deps/cava /usr/local/bin/cava 2>/dev/null || cp mac_deps/cava /usr/local/bin/cava
        sudo cp mac_deps/libportaudio*.dylib mac_deps/libfftw3*.dylib mac_deps/libiniparser*.dylib /usr/local/lib/ 2>/dev/null
        chmod +x /usr/local/bin/cava
        echo "[OK] cava kuruldu (mac_deps)"
    else
        echo "[!] cava yok. 'brew install cava' ile kurun ya da mac_deps klasorunu ekleyin."
        read -p "Enter..."; exit 1
    fi
else
    echo "[OK] cava mevcut"
fi

# --- 4) C sensor araclarini derle (sysmon icin) ---
echo "[*] Sensor araclari derleniyor..."
for tool in smc_read gpu_read disk_read ipg_read; do
    if [ -f "${tool}.c" ] && [ ! -x "${tool}" ]; then
        case "$tool" in
            ipg_read) clang -o "$tool" "${tool}.c" -framework IntelPowerGadget -F /Library/Frameworks 2>/dev/null ;;
            *)        clang -o "$tool" "${tool}.c" -framework IOKit -framework CoreFoundation 2>/dev/null ;;
        esac
        [ -x "$tool" ] && echo "    + $tool derlendi" || echo "    - $tool derlenemedi (o sensor bos gorunur)"
    fi
done

# --- 5) Uygulama dosyalari ---
APP="/Applications/VU Meter Masaustu.app"

# ikon uret
if [ ! -f vu_icon.icns ] && [ -f app_icon_1024.png ]; then
    rm -rf /tmp/vu.iconset; mkdir -p /tmp/vu.iconset
    for s in 16 32 128 256 512; do
        sips -z $s $s app_icon_1024.png --out "/tmp/vu.iconset/icon_${s}x${s}.png" >/dev/null 2>&1
        d=$((s*2))
        sips -z $d $d app_icon_1024.png --out "/tmp/vu.iconset/icon_${s}x${s}@2x.png" >/dev/null 2>&1
    done
    iconutil -c icns /tmp/vu.iconset -o vu_icon.icns 2>/dev/null && echo "[OK] ikon uretildi"
fi

echo "[*] Launcher derleniyor..."
clang -fobjc-arc -o vu_launcher_desktop vu_launcher_desktop.m \
      -framework Foundation -framework AVFoundation 2>/dev/null \
  && echo "[OK] launcher derlendi" || { echo "[!] launcher derlenemedi"; read -p "Enter..."; exit 1; }

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/app"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>VU Meter Masaustu</string>
    <key>CFBundleIdentifier</key><string>com.mhrpii.vumeterdesktop</string>
    <key>CFBundleExecutable</key><string>vu_launcher_desktop</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleIconFile</key><string>vu_icon</string>
    <key>NSMicrophoneUsageDescription</key><string>VU Meter, ses kartindan gelen sesi gorsellestirmek icin ses girisini kullanir.</string>
</dict>
</plist>
PLIST

cp vu_icon.icns "$APP/Contents/Resources/" 2>/dev/null
cp vu_launcher_desktop "$APP/Contents/MacOS/"
chmod +x "$APP/Contents/MacOS/vu_launcher_desktop"
cp *.py                                  "$APP/Contents/Resources/app/" 2>/dev/null
cp *.png                                 "$APP/Contents/Resources/app/" 2>/dev/null
cp smc_read gpu_read disk_read ipg_read  "$APP/Contents/Resources/app/" 2>/dev/null

# --- 8) Ikon (camgobegi tonlu - LCD'den ayirt edilsin) ---
if [ -f "app_icon_1024.png" ]; then
    TMP="$(mktemp -d)"; ICONSET="$TMP/appicon.iconset"; mkdir -p "$ICONSET"
    for sz in 16 32 64 128 256 512; do
        sips -z $sz $sz app_icon_1024.png --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null 2>&1
        d=$((sz*2)); sips -z $d $d app_icon_1024.png --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null 2>&1
    done
    cp app_icon_1024.png "$ICONSET/icon_512x512@2x.png"
    iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/appicon.icns" 2>/dev/null
fi
touch "$APP"

echo ""
echo "=================================================="
echo "[OK] Kurulum tamam: $APP"
echo "     Launchpad'den 'VU Meter Masaustu' ile acin."
echo "     Kisayollar: 1-6 mod, TAB tema, C kanal, W sistem monitoru, Q cikis"
echo "=================================================="
read -p "Kapatmak icin Enter..."
