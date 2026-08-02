#!/bin/bash
#
# baslat.command — VU Meter LCD baslat
# Cift tikla calistir. Paneli acar.
#
cd "$(dirname "$0")" || exit 1

# eski surecleri temizle (USB kilidi olmasin)
pkill -f native_proto_mac 2>/dev/null
sleep 1

# numpy sistem python3'unde (3.9) kurulu; Homebrew python3 PATH'te
# one gecerse numpy bulunamiyor. Bu yuzden yolu sabitliyoruz.
PYBIN="/usr/bin/python3"
[ -x "$PYBIN" ] || PYBIN="$(command -v python3)"
if [ -z "$PYBIN" ]; then
    echo "python3 bulunamadi. Once kur.command calistir."
    read -p "Enter ile kapat..."
    exit 1
fi

# smc_read/gpu_read/disk_read/ipg_read yoksa sysmon_mac otomatik derler.
# Paneli baslat.
echo "VU Meter LCD baslatiliyor... (kapatmak icin bu pencereyi kapat ya da Ctrl+C)"
"$PYBIN" native_proto_mac.py "Spektrum"

# hata durumunda pencere kapanmasin
echo ""
read -p "Uygulama kapandi. Enter ile pencereyi kapat..."
