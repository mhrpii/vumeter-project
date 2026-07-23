# -*- mode: python ; coding: utf-8 -*-
# VU Meter LCD - PyInstaller spec (mikrofon izni icin .app kimligi sart)

datas = [
    ('vu_bg.png', '.'),
    ('vu_bg2.png', '.'),
    ('vu_bg3.png', '.'),
    ('app_icon_1024.png', '.'),
    ('smc_read', '.'),
    ('gpu_read', '.'),
    ('disk_read', '.'),
    ('ipg_read', '.'),
]

hidden = [
    'sounddevice', 'numpy', 'PIL', 'PIL.Image', 'psutil', 'usb', 'usb.core',
    'usb.util', 'PyQt5', 'PyQt5.QtWidgets', 'PyQt5.QtGui', 'PyQt5.QtCore',
    'sysmon_mac', 'trcc_direct', 'control_window',
]

a = Analysis(
    ['native_proto_mac.py'],
    pathex=['.'],
    binaries=[],
    datas=datas,
    hiddenimports=hidden,
    hookspath=[],
    runtime_hooks=[],
    excludes=['tkinter', 'matplotlib'],
    noarchive=False,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz, a.scripts, [],
    exclude_binaries=True,
    name='VU Meter LCD',
    debug=False,
    strip=False,
    upx=False,
    console=False,
)

coll = COLLECT(
    exe, a.binaries, a.datas,
    strip=False, upx=False,
    name='VU Meter LCD',
)

app = BUNDLE(
    coll,
    name='VU Meter LCD.app',
    icon=None,
    bundle_identifier='com.mhrpii.vumeterlcd',
    info_plist={
        'LSUIElement': True,
        'NSMicrophoneUsageDescription':
            'VU Meter, ses kartindan gelen sesi gorsellestirmek icin ses girisini kullanir.',
        'CFBundleName': 'VU Meter LCD',
        'CFBundleDisplayName': 'VU Meter LCD',
        'CFBundleVersion': '1.0',
        'CFBundleShortVersionString': '1.0',
        'LSMinimumSystemVersion': '10.13',
    },
)
