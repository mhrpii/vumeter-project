#!/bin/bash
APP="/Applications/VU Meter LCD Baslat.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cat > "$APP/Contents/Info.plist" << 'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>VU Meter LCD Baslat</string>
    <key>CFBundleIdentifier</key><string>com.mhrpii.vumeterlcd.baslat</string>
    <key>CFBundleExecutable</key><string>baslat</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PL
cat > "$APP/Contents/MacOS/baslat" << 'SH'
#!/bin/bash
osascript -e 'tell application "Terminal"
    do script "pkill -f native_proto_mac; pkill -f \"cava -p\"; sleep 2; cd /Volumes/Ydk_w/TRCCMacveLinuxversiyonu/files_Linux/files && python3 -u native_proto_mac.py Spektrum"
end tell'
SH
chmod +x "$APP/Contents/MacOS/baslat"
echo "sarmalayici kuruldu: $APP"
