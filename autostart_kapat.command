#!/bin/bash
# VU Meter LCD - Autostart KAPAT
LA_PLIST="$HOME/Library/LaunchAgents/com.vumeter.lcd.plist"

if [ -f "$LA_PLIST" ]; then
    launchctl unload "$LA_PLIST" 2>/dev/null
    rm -f "$LA_PLIST"
    echo "[OK] Autostart KAPATILDI."
    echo "     Mac acilinca panel artik otomatik baslamayacak."
    echo "     Tekrar acmak icin: autostart_ac.command"
else
    echo "[i] Autostart zaten kapali (LaunchAgent yok)."
fi
read -p "Enter..."
