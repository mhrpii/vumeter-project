#!/bin/bash
#
# kur.command — VU Meter LCD Mac kurulum + Applications'a .app kur
#
cd "$(dirname "$0")" || exit 1

echo "=================================================="
echo "  VU Meter LCD — Mac Kurulum"
echo "=================================================="
echo ""

# --- 1) Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
    echo "[!] Homebrew yok. Kur: https://brew.sh"
    read -p "Homebrew'suz cava/libusb kurulamaz. Enter ile devam..."
else
    echo "[✓] Homebrew bulundu."
fi

# --- 2) cava + libusb ---
echo ""
echo "[*] cava + libusb kuruluyor..."
if command -v brew >/dev/null 2>&1; then
    brew list cava   >/dev/null 2>&1 || brew install cava
    brew list libusb >/dev/null 2>&1 || brew install libusb
    echo "[✓] cava + libusb hazir."
fi

# --- 3) Python kutuphaneleri ---
echo ""
echo "[*] Python kutuphaneleri kuruluyor..."
PYBIN="$(command -v python3)"
[ -z "$PYBIN" ] && { echo "[!] python3 yok: xcode-select --install"; read -p "Enter..."; }
"$PYBIN" -m pip install --user pygame PyQt5 numpy psutil pyusb 2>&1 | tail -2
echo "[✓] Python kutuphaneleri hazir."

# --- 4) C araclarini derle ---
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

# --- 5) .app bundle olustur ---
echo ""
echo "[*] Uygulama (.app) olusturuluyor..."
APP="/Applications/VU Meter LCD.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources/app"

cp *.py                                 "$APP/Contents/Resources/app/" 2>/dev/null
cp *.c                                  "$APP/Contents/Resources/app/" 2>/dev/null
cp smc_read gpu_read disk_read ipg_read "$APP/Contents/Resources/app/" 2>/dev/null
cp *.png                                "$APP/Contents/Resources/app/" 2>/dev/null

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>VU Meter LCD</string>
    <key>CFBundleDisplayName</key><string>VU Meter LCD</string>
    <key>CFBundleIdentifier</key><string>com.mhrpii.vumeterlcd</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundleExecutable</key><string>launcher</string>
    <key>CFBundleIconFile</key><string>appicon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>10.13</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

cat > "$APP/Contents/MacOS/launcher" << 'LAUNCH'
#!/bin/bash
DIR="$(cd "$(dirname "$0")/../Resources/app" && pwd)"
cd "$DIR" || exit 1
pkill -f native_proto_mac 2>/dev/null
sleep 1
PY="$(command -v python3)"
exec "$PY" native_proto_mac.py "Spektrum"
LAUNCH
chmod +x "$APP/Contents/MacOS/launcher"

if [ -f "app_icon_1024.png" ]; then
    TMP="$(mktemp -d)"
    ICONSET="$TMP/appicon.iconset"
    mkdir -p "$ICONSET"
    for sz in 16 32 64 128 256 512; do
        sips -z $sz $sz app_icon_1024.png --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null 2>&1
        d=$((sz*2))
        sips -z $d $d app_icon_1024.png --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null 2>&1
    done
    cp app_icon_1024.png "$ICONSET/icon_512x512@2x.png"
    iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/appicon.icns" 2>/dev/null \
        && echo "    [OK] ikon olusturuldu" || echo "    [!] ikon olusturulamadi"
fi

# Finder ikonu tazelesin
touch "$APP"

echo "[OK] Uygulama kuruldu: $APP"
echo ""
echo "=================================================="
echo "  Kurulum tamamlandi!"
echo ""
echo "  - Launchpad ya da Spotlight'ta 'VU Meter LCD' ara"
echo "  - Paneli tak, uygulamaya cift tikla"
echo ""
echo "  Ilk acilista 'gelistirici dogrulanamadi' derse:"
echo "  Sag tik -> Ac -> Ac"
echo "=================================================="
echo ""
read -p "Kapatmak icin Enter..."
