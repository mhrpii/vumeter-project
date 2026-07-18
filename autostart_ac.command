#!/bin/bash
# VU Meter LCD - Autostart AC (Mac acilinca panel otomatik baslar)
cd "$(dirname "$0")" || exit 1

APP="/Applications/VU Meter LCD.app"
if [ ! -d "$APP" ]; then
    echo "[!] Once kur.command ile uygulamayi kurun (.app bulunamadi)."
    read -p "Enter..."
    exit 1
fi

LA_DIR="$HOME/Library/LaunchAgents"
LA_PLIST="$LA_DIR/com.vumeter.lcd.plist"
mkdir -p "$LA_DIR"
cat > "$LA_PLIST" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.vumeter.lcd</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP/Contents/MacOS/launcher</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
PLIST

launchctl unload "$LA_PLIST" 2>/dev/null
launchctl load "$LA_PLIST" 2>/dev/null

echo "[OK] Autostart ACILDI."
echo "     Mac her acildiginda panel otomatik baslayacak."
echo "     Kapatmak icin: autostart_kapat.command"
read -p "Enter..."
