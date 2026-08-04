#!/bin/bash
# vumeter-desktop .deb kurulum scripti
# Kullanim: bash build_desktop_deb.sh > /tmp/deb-desktop.txt 2>&1
set -x

SRC="$(cd "$(dirname "$0")" && pwd)"
ROOT=~/vumeter-deb-build/vumeter-desktop_2.0.0

# ---- 1) Paket agaci ----
rm -rf "$ROOT"
mkdir -p "$ROOT/DEBIAN" \
         "$ROOT/opt/vumeter-desktop" \
         "$ROOT/usr/bin" \
         "$ROOT/usr/share/applications"

# ---- 2) Uygulama dosyalari ----
for f in vumeter_linux.py control_window_desktop.py sysmon.py sysmon_window.py vu_bg.png vu_bg2.png vu_bg3.png; do
    cp "$SRC/$f" "$ROOT/opt/vumeter-desktop/" || { echo "EKSIK DOSYA: $f"; exit 1; }
done
cp "$SRC/Linux_NCT6687D_9FAN_KURULUM.md" "$ROOT/opt/vumeter-desktop/" 2>/dev/null || true
cp "$SRC/DEBIAN_SIFIR_KURULUM.md" "$ROOT/opt/vumeter-desktop/" 2>/dev/null || true

# ---- 3) DEBIAN/control ----
cat > "$ROOT/DEBIAN/control" << 'EOF'
Package: vumeter-desktop
Version: 2.0.0
Section: sound
Priority: optional
Architecture: all
Depends: python3, python3-pygame, python3-numpy, python3-psutil, python3-pyqt5,
 python3-pil, cava, lm-sensors, pipewire-pulse | pulseaudio-utils
Recommends: dkms, build-essential
Maintainer: Mahir
Description: Masaustu Ses Gorsellestirme ve Sistem Monitoru
 Vintage Audio Console masaustu surumu: spektrum (2 tip), LED spektrum,
 LED nokta, VU metre (3 kadran), olcum paneli ve 21 barli sistem monitoru.
 Tepsi ikonu ile mod/tema/kadran secimi. cava (PipeWire) gerektirir.
EOF

# ---- 4) Baslatici ----
cat > "$ROOT/usr/bin/vumeter-desktop" << 'EOF'
#!/bin/bash
cd /opt/vumeter-desktop
exec python3 /opt/vumeter-desktop/vumeter_linux.py "$@"
EOF
chmod 755 "$ROOT/usr/bin/vumeter-desktop"

# ---- 5) Uygulama menusu girisi ----
cat > "$ROOT/usr/share/applications/vumeter-desktop.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Vumeter Desktop
Comment=Vintage Audio Console - masaustu ses gorsellestirme
Exec=vumeter-desktop
Icon=multimedia-volume-control
Terminal=false
Categories=AudioVideo;Audio;
EOF

# ---- 6) postinst ----
cat > "$ROOT/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# RAPL enerji sayaci okuma izni (CPU gucu icin)
cat > /etc/udev/rules.d/99-rapl-read.rules << 'RULE'
SUBSYSTEM=="powercap", ACTION=="add|change", RUN+="/bin/chmod 0444 /sys%p/energy_uj"
RULE
udevadm control --reload-rules 2>/dev/null || true
chmod 0444 /sys/class/powercap/intel-rapl:0/energy_uj 2>/dev/null || true

# SATA disk sicakliklari icin drivetemp modulu
echo "drivetemp" > /etc/modules-load.d/drivetemp.conf
modprobe drivetemp 2>/dev/null || true

echo ""
echo "======================================================"
echo " vumeter-desktop kuruldu!"
echo ""
echo " Calistirmak icin: vumeter-desktop"
echo " (veya uygulama menusunden 'Vumeter Desktop')"
echo ""
echo " Tuslar: 1-6 modlar, TAB tema/kadran, W monitor, Q cikis"
echo " Tepsi ikonu: sag tik -> mod/tema/kadran/cikis"
echo "======================================================"
exit 0
EOF
chmod 755 "$ROOT/DEBIAN/postinst"

cat > "$ROOT/DEBIAN/prerm" << 'EOF'
#!/bin/bash
rm -f /etc/udev/rules.d/99-rapl-read.rules
udevadm control --reload-rules 2>/dev/null || true
exit 0
EOF
chmod 755 "$ROOT/DEBIAN/prerm"

# ---- 7) Izinler + derle + kur ----
chmod 644 "$ROOT/opt/vumeter-desktop/"*
chmod 644 "$ROOT/usr/share/applications/vumeter-desktop.desktop"

dpkg-deb --build --root-owner-group "$ROOT" ~/vumeter-deb-build/vumeter-desktop_1.0.0.deb
sudo dpkg -i ~/vumeter-deb-build/vumeter-desktop_1.0.0.deb

# ---- 8) Dogrulama ----
dpkg -s vumeter-desktop | grep -E '^(Package|Version|Status)'
ls -la /opt/vumeter-desktop/
which vumeter-desktop && echo "KURULUM OK"
