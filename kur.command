#!/bin/bash
#
# kur.command — VU Meter LCD Mac kurulum
# Cift tikla calistir. Tum bagimliliklari kurar ve C araclarini derler.
#
# Bu script'in bulundugu klasorde calisir (dosyalar burada olmali).

cd "$(dirname "$0")" || exit 1

echo "=================================================="
echo "  VU Meter LCD — Mac Kurulum"
echo "=================================================="
echo ""

# --- 1) Homebrew kontrolu ---
if ! command -v brew >/dev/null 2>&1; then
    echo "[!] Homebrew kurulu degil."
    echo "    Once Homebrew kur: https://brew.sh"
    echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    echo ""
    read -p "Devam etmek icin Enter (Homebrew olmadan cava/libusb kurulamaz)..."
else
    echo "[✓] Homebrew bulundu."
fi

# --- 2) Homebrew paketleri: cava + libusb ---
echo ""
echo "[*] cava ve libusb kuruluyor (ses + USB)..."
if command -v brew >/dev/null 2>&1; then
    brew list cava >/dev/null 2>&1 || brew install cava
    brew list libusb >/dev/null 2>&1 || brew install libusb
    echo "[✓] cava + libusb hazir."
fi

# --- 3) Python kutuphaneleri ---
echo ""
echo "[*] Python kutuphaneleri kuruluyor..."
PYBIN="$(command -v python3)"
if [ -z "$PYBIN" ]; then
    echo "[!] python3 bulunamadi. Xcode Command Line Tools kur: xcode-select --install"
    read -p "Enter ile devam..."
fi
"$PYBIN" -m pip install --user pygame PyQt5 numpy psutil pyusb 2>&1 | tail -3
echo "[✓] Python kutuphaneleri hazir."

# --- 4) C sensor araclarini derle ---
echo ""
echo "[*] C sensor araclari derleniyor..."
if ! command -v clang >/dev/null 2>&1; then
    echo "[!] clang yok. Xcode Command Line Tools gerekli: xcode-select --install"
    read -p "Enter ile devam..."
fi

compile_tool() {
    local out="$1"; shift
    local src="$1"; shift
    if [ -f "$src" ]; then
        if clang -O2 -o "$out" "$src" "$@" 2>/dev/null; then
            echo "    [✓] $out"
        else
            echo "    [!] $out derlenemedi (bu sensor calismayabilir)"
        fi
    fi
}

compile_tool smc_read  smc_read.c  -framework IOKit -framework CoreFoundation
compile_tool gpu_read  gpu_read.c  -framework IOKit -framework CoreFoundation
compile_tool disk_read disk_read.c -framework IOKit -framework CoreFoundation
# ipg_read: Intel Power Gadget framework gerekir
if [ -d "/Library/Frameworks/IntelPowerGadget.framework" ]; then
    compile_tool ipg_read ipg_read.c -F/Library/Frameworks -framework IntelPowerGadget
else
    echo "    [!] Intel Power Gadget kurulu degil — 24 cekirdek isi haritasi calismayacak."
    echo "        Kurmak icin: https://www.intel.com/content/www/us/en/developer/articles/tool/power-gadget.html"
fi

# --- 5) Intel Power Gadget kontrolu ---
echo ""
if [ ! -d "/Library/Frameworks/IntelPowerGadget.framework" ]; then
    echo "[NOT] Intel Power Gadget kurulu degil (opsiyonel):"
    echo "      - 24 cekirdek isi haritasi (sayfa 3) icin gerekli"
    echo "      - Diger her sey Intel Power Gadget olmadan da calisir"
fi

echo ""
echo "=================================================="
echo "  Kurulum tamamlandi!"
echo "  Baslatmak icin: baslat.command (cift tikla)"
echo "=================================================="
echo ""
read -p "Kapatmak icin Enter..."
