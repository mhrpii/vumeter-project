#!/bin/bash
cd "$(dirname "$0")" || exit 1

APP_NAME="VU Meter Masaustu Tahoe"
DMG_NAME="VU_Meter_Masaustu_Tahoe"
STAGING="$(mktemp -d)/VU Meter Masaustu Tahoe"
mkdir -p "$STAGING"

echo "=== VU Meter Masaustu (Tahoe) .dmg olusturuluyor ==="
echo ""
echo "[*] Dosyalar toplaniyor..."

for f in vumeter_mac_desktop.py sysmon_mac.py sysmon_window.py control_window_desktop.py; do
    [ -f "$f" ] && cp "$f" "$STAGING/" && echo "    + $f"
done

for f in smc_read.c gpu_read.c disk_read.c ipg_read.c; do
    [ -f "$f" ] && cp "$f" "$STAGING/" && echo "    + $f"
done

for f in kur_masaustu.command README_MAC.md app_icon_1024.png; do
    [ -f "$f" ] && cp "$f" "$STAGING/" && echo "    + $f"
done

for f in vu_bg.png vu_bg2.png vu_bg3.png; do
    [ -f "$f" ] && cp "$f" "$STAGING/" && echo "    + $f"
done

if [ -d "mac_deps" ]; then
    cp -R mac_deps "$STAGING/"
    echo "    + mac_deps/"
fi

chmod +x "$STAGING/kur_masaustu.command" 2>/dev/null

cat > "$STAGING/1_OKU_ONCE.txt" << 'TXT'
VU Meter Masaustu — Tahoe (macOS 26) Kurulumu

1) Bu klasorun TAMAMINI Masaustu'ne KOPYALA.
   (.dmg icinden dogrudan calistirma.)

2) "kur_masaustu.command" dosyasina CIFT TIKLA.
   - Gelistirici uyarisi cikarsa: Sag tik -> Ac -> Ac

3) SES: Sistem Ayarlari > Ses > Cikis = loopback ozellikli ses karti
   (ornek: Focusrite Scarlett). Ek yazilim gerekmez.

4) Launchpad'den "VU Meter Masaustu" ile ac.
   Ilk acilista Terminal otomasyon izni sorulur -> Izin Ver.
   (Mikrofon izni imzasiz uygulamalara verilmedigi icin uygulama
    Terminal uzerinden baslatilir; pencere gizlidir.)

Tuslar: 1-6 mod, TAB tema/kadran, W sistem monitoru, Q cikis

Detayli aciklama: README_MAC.md
TXT

ln -s /Applications "$STAGING/../Applications" 2>/dev/null

echo ""
echo "[*] .dmg paketleniyor..."
rm -f "${DMG_NAME}.dmg"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$(dirname "$STAGING")" \
    -ov -format UDZO \
    "${DMG_NAME}.dmg" >/dev/null 2>&1

if [ -f "${DMG_NAME}.dmg" ]; then
    SIZE="$(du -h "${DMG_NAME}.dmg" | cut -f1)"
    echo "[OK] Olusturuldu: ${DMG_NAME}.dmg ($SIZE)"
else
    echo "[!] .dmg olusturulamadi."
fi

echo ""
read -p "Kapatmak icin Enter..."
