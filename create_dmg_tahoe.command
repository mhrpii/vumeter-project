#!/bin/bash
#
# create_dmg_tahoe.command — VU Meter LCD (Tahoe surumu) .dmg olusturur
#
# Tahoe farklari:
#   - kur_sarmalayici.command dahil (mikrofon izni icin Terminal sarmalayici)
#   - launcher_main.c (C launcher) dahil
#   - aggregate/BlackHole yok; Scarlett + channels=1 dogrudan calisir
#
cd "$(dirname "$0")" || exit 1

APP_NAME="VU Meter LCD Tahoe"
DMG_NAME="VU_Meter_LCD_Tahoe"
STAGING="$(mktemp -d)/VU Meter LCD Tahoe"
mkdir -p "$STAGING"

echo "=== VU Meter LCD (Tahoe) .dmg olusturuluyor ==="
echo ""
echo "[*] Dosyalar toplaniyor..."

for f in native_proto_mac.py sysmon_mac.py control_window.py trcc_direct.py; do
    [ -f "$f" ] && cp "$f" "$STAGING/" && echo "    + $f"
done

for f in smc_read.c gpu_read.c disk_read.c ipg_read.c launcher_main.c; do
    [ -f "$f" ] && cp "$f" "$STAGING/" && echo "    + $f"
done

for f in kur.command kur_sarmalayici.command README_MAC.md app_icon_1024.png vumeter.spec; do
    [ -f "$f" ] && cp "$f" "$STAGING/" && echo "    + $f"
done

for f in vu_bg.png vu_bg2.png vu_bg3.png; do
    [ -f "$f" ] && cp "$f" "$STAGING/" && echo "    + $f"
done

if [ -d "mac_deps" ]; then
    cp -R mac_deps "$STAGING/"
    echo "    + mac_deps/ ($(ls mac_deps | wc -l | tr -d ' ') dosya)"
fi

chmod +x "$STAGING/kur.command" "$STAGING/kur_sarmalayici.command" 2>/dev/null

cat > "$STAGING/1_OKU_ONCE.txt" << 'TXT'
VU Meter LCD — Tahoe (macOS 26) Kurulumu

1) Bu klasorun TAMAMINI Masaustu'ne KOPYALA.
   (.dmg icinden dogrudan calistirma.)

2) "kur.command" dosyasina CIFT TIKLA.
   - Gelistirici uyarisi cikarsa: Sag tik -> Ac -> Ac
   - Python kutuphanelerini kurar, C araclarini derler,
     uygulamayi /Applications'a koyar.

3) "kur_sarmalayici.command" dosyasina CIFT TIKLA.
   - "VU Meter LCD Baslat" adinda bir uygulama olusturur.
   - Tahoe'da mikrofon izni imzasiz uygulamalara verilmedigi icin
     uygulama Terminal uzerinden baslatilir. Bu sarmalayici onu yapar.

4) SES: Sistem Ayarlari > Ses > Cikis = loopback ozellikli ses karti
   (ornek: Focusrite Scarlett). Ek yazilim (BlackHole vb.) gerekmez.

5) Paneli tak, Launchpad'de "VU Meter LCD Baslat" ile ac.
   Ilk acilista Terminal otomasyon izni sorulur -> Izin Ver.

NOT: Uygulamayi dogrudan "VU Meter LCD" ile acarsan panel calisir
ama ses barlari gelmez (mikrofon izni yok). Her zaman "Baslat" ile ac.

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
