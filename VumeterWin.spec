# -*- mode: python ; coding: utf-8 -*-
"""VintageAudioConsole - Windows .exe paketleme (PyInstaller)

Kullanim:
    py -3.12 -m pip install pyinstaller
    py -3.12 -m PyInstaller VumeterWin.spec --clean

Cikti: dist\\VintageAudioConsole.exe   (tek dosya, Python gerekmez)

Not: Ilk denemede console=False birakildi -> hata olursa terminalde gorunur.
     Her sey calisinca console=False yapip yeniden derleyebilirsin (siyah
     terminal penceresi acilmaz).
"""

block_cipher = None

a = Analysis(
    ['vumeter_win.py'],
    pathex=[],
    binaries=[],
    datas=[
        # VU kadran arka planlari (get_resource_path ile okunuyor)
        ('vu_bg.png', '.'),
        ('vu_bg2.png', '.'),
        ('vu_bg3.png', '.'),
        # kontrol penceresi modulu (sol tik ile aciliyor)
        ('control_window_desktop.py', '.'),
    ],
    hiddenimports=[
        # ses yakalama (WASAPI loopback)
        'soundcard',
        'soundcard.mediafoundation',
        'cffi',
        '_cffi_backend',
        # ses seviyesi (pycaw + comtypes)
        'pycaw',
        'pycaw.pycaw',
        'pycaw.utils',
        'comtypes',
        'comtypes.client',
        'comtypes.stream',
        # kontrol penceresi (runtime'da import ediliyor)
        'control_window_desktop',
        # arayuz
        'PyQt5.QtCore',
        'PyQt5.QtGui',
        'PyQt5.QtWidgets',
        'numpy',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        # gereksiz agir paketler (varsa) - exe boyutunu kucultur
        'matplotlib', 'scipy', 'pandas', 'tkinter', 'PySide2', 'PySide6',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='VintageAudioConsole',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,          # hata ayiklama icin acik; sorunsuz calisinca False yap
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
