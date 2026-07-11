"""Windows sistem sensorleri - LibreHardwareMonitorLib.dll (pythonnet).

Linux'taki sysmon.py ile AYNI arayuz: SysMonitor().snapshot() -> dict, .stop()

GEREKSINIM:
  - py -3.12 -m pip install pythonnet
  - LibreHardwareMonitorLib.dll + HidSharp.dll + System.*.dll  (bu klasorde)
  - UYGULAMA YONETICI OLARAK CALISMALI (sicaklik/fan icin sart)

Donanim: MSI MEG Z890 GODLIKE (NCT6687D) + Intel Core Ultra 9 285K + RX 6900 XT
"""
import os
import sys
import time
import threading
import ctypes

_LHM_OK = False
_ERR = ""

try:
    import clr  # pythonnet
    _HERE = os.path.dirname(os.path.abspath(__file__))
    _DLL = os.path.join(_HERE, "LibreHardwareMonitorLib.dll")
    if not os.path.exists(_DLL):
        # PyInstaller ile paketlenmisse
        _DLL = os.path.join(getattr(sys, "_MEIPASS", _HERE), "LibreHardwareMonitorLib.dll")
    clr.AddReference(_DLL)
    from LibreHardwareMonitor.Hardware import Computer
    _LHM_OK = True
except Exception as e:
    _ERR = str(e)


def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False


def _num(v):
    return None if v is None else float(v)


class SysMonitor:
    """Arka planda LHM'yi guncelleyip degerleri onbellege alir.
    snapshot() -> Linux sysmon.py ile ayni anahtarlarda dict."""

    def __init__(self, interval=1.0):
        self.interval = interval
        self._lock = threading.Lock()
        self._data = {}
        self._run = True
        self._c = None
        self._net_hw = None
        if not _LHM_OK:
            print("sysmon_win: LHM yuklenemedi ->", _ERR)
            return
        if not is_admin():
            print("sysmon_win: UYARI - yonetici degil, sicaklik/fan gelmeyebilir!")
        self._t = threading.Thread(target=self._loop, daemon=True)
        self._t.start()

    # ---------- ic yardimcilar ----------
    @staticmethod
    def _sens(hw, stype, name):
        for s in hw.Sensors:
            if str(s.SensorType) == stype and str(s.Name) == name:
                return _num(s.Value)
        return None

    @staticmethod
    def _sens_any(hw, stype, names):
        for n in names:
            v = SysMonitor._sens(hw, stype, n)
            if v is not None:
                return v
        return None

    @staticmethod
    def _update(hw):
        hw.Update()
        for s in hw.SubHardware:
            SysMonitor._update(s)

    def _loop(self):
        try:
            c = Computer()
            c.IsCpuEnabled = True
            c.IsGpuEnabled = True
            c.IsMotherboardEnabled = True
            c.IsMemoryEnabled = True
            c.IsNetworkEnabled = True
            c.IsControllerEnabled = True
            c.IsStorageEnabled = False
            c.Open()
            self._c = c
        except Exception as e:
            print("sysmon_win: Computer.Open hatasi:", e)
            return

        while self._run:
            try:
                for hw in self._c.Hardware:
                    self._update(hw)
                d = self._collect()
                with self._lock:
                    self._data = d
            except Exception as e:
                print("sysmon_win: guncelleme hatasi:", e)
            time.sleep(self.interval)

        try:
            self._c.Close()
        except Exception:
            pass

    def _collect(self):
        d = {}
        cpu_clocks = []
        dimm_temps = []
        best_net = None
        best_net_total = -1.0

        for hw in self._c.Hardware:
            ht = str(hw.HardwareType)
            nm = str(hw.Name)

            # ---------- CPU ----------
            if ht == "Cpu":
                d["cpu_pkg"] = self._sens(hw, "Temperature", "CPU Package")
                d["cores_max"] = self._sens_any(hw, "Temperature", ["Core Max", "Core Average"])
                d["cpu_usage"] = self._sens(hw, "Load", "CPU Total")
                d["cpu_power"] = self._sens(hw, "Power", "CPU Package")
                for s in hw.Sensors:
                    if str(s.SensorType) == "Clock" and str(s.Name) != "Bus Speed":
                        v = _num(s.Value)
                        if v:
                            cpu_clocks.append(v)

            # ---------- GPU ----------
            elif ht.startswith("Gpu"):
                d["gpu_junction"] = self._sens_any(hw, "Temperature", ["GPU Hot Spot", "GPU Core"])
                d["gpu_edge"] = self._sens(hw, "Temperature", "GPU Core")
                d["gpu_power"] = self._sens_any(hw, "Power", ["GPU Package", "GPU Power"])
                d["gpu_fan_rpm"] = self._sens(hw, "Fan", "GPU Fan")
                gl = self._sens(hw, "Load", "GPU Core")
                if gl is None:
                    gl = self._sens(hw, "Load", "D3D 3D")
                d["gpu_usage"] = gl
                vu = self._sens(hw, "SmallData", "GPU Memory Used")
                vt = self._sens(hw, "SmallData", "GPU Memory Total")
                d["gpu_vram_used"] = (vu / 1024.0) if vu else None      # MB -> GB
                d["gpu_vram_total"] = (vt / 1024.0) if vt else None

            # ---------- Anakart (NCT6687D alt donanimda) ----------
            elif ht == "Motherboard":
                for sub in hw.SubHardware:
                    d["mb_vrm"] = self._sens_any(sub, "Temperature", ["VRM MOS", "VRM"])
                    d["mb_pch"] = self._sens_any(sub, "Temperature", ["Chipset", "PCH"])
                    d["mb_system"] = self._sens_any(sub, "Temperature", ["System", "Motherboard"])
                    d["fan_cpu"] = self._sens(sub, "Fan", "CPU Fan")
                    d["fan_pump"] = self._sens_any(sub, "Fan", ["Pump Fan #1", "Pump Fan"])
                    d["fan_chipset"] = self._sens(sub, "Fan", "Chipset Fan")
                    for i in range(1, 7):
                        d[f"fan_sys{i}"] = self._sens(sub, "Fan", f"System Fan #{i}")

            # ---------- RAM ----------
            elif ht == "Memory":
                if nm == "Total Memory" or (d.get("ram_pct") is None and "Virtual" not in nm):
                    v = self._sens(hw, "Load", "Memory")
                    if v is not None and nm != "Virtual Memory":
                        d["ram_pct"] = v
                # DIMM sicakligi (GPU bellek sicakligi yok -> onun yerine)
                for s in hw.Sensors:
                    if str(s.SensorType) == "Temperature" and str(s.Name).startswith("DIMM"):
                        v = _num(s.Value)
                        if v:
                            dimm_temps.append(v)

            # ---------- Ag ----------
            elif ht == "Network":
                dn = self._sens(hw, "Throughput", "Download Speed") or 0.0
                up = self._sens(hw, "Throughput", "Upload Speed") or 0.0
                tot_d = self._sens(hw, "Data", "Data Downloaded") or 0.0
                if tot_d > best_net_total:
                    best_net_total = tot_d
                    best_net = (dn, up)

        # CPU frekans (MHz) - en yuksek cekirdek
        d["cpu_freq"] = max(cpu_clocks) if cpu_clocks else None

        # GPU bellek sicakligi yok -> DIMM (RAM modulu) sicakligi
        d["gpu_mem"] = max(dimm_temps) if dimm_temps else None

        # Ag: bytes/s -> MiB/s (Linux sysmon ile ayni birim)
        if best_net:
            d["net_down"] = best_net[0] / 1048576.0
            d["net_up"] = best_net[1] / 1048576.0
        else:
            d["net_down"] = d["net_up"] = None

        return d

    def snapshot(self):
        with self._lock:
            return dict(self._data)

    def stop(self):
        self._run = False


if __name__ == "__main__":
    m = SysMonitor()
    print("Yonetici:", is_admin(), " LHM:", _LHM_OK)
    for _ in range(3):
        time.sleep(1.5)
        d = m.snapshot()
        if not d:
            print("veri yok...")
            continue
        print(f"CPU {d.get('cpu_pkg')}C  Cekirdek {d.get('cores_max')}C  "
              f"GPU {d.get('gpu_junction')}C  GEdge {d.get('gpu_edge')}C")
        print(f"VRM {d.get('mb_vrm')}C  PCH {d.get('mb_pch')}C  Sys {d.get('mb_system')}C  "
              f"DIMM {d.get('gpu_mem')}C")
        print(f"CFan {d.get('fan_cpu')}  Pump {d.get('fan_pump')}  GFan {d.get('gpu_fan_rpm')}  "
              f"S2 {d.get('fan_sys2')}")
        print(f"CPU% {d.get('cpu_usage')}  GPU% {d.get('gpu_usage')}  RAM% {d.get('ram_pct')}  "
              f"VRAM {d.get('gpu_vram_used')}GB")
        print(f"GHz {d.get('cpu_freq')}  C-W {d.get('cpu_power')}  G-W {d.get('gpu_power')}  "
              f"Net dn {d.get('net_down')} up {d.get('net_up')} MiB/s")
        print("-" * 60)
    m.stop()
