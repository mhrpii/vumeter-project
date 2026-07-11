"""Bagimsiz Sistem Monitoru penceresi (VintageVU'dan ayri surec olarak acilir).
LCD surumundeki GAUGE (dairesel halka) tasarimi: halka boyunca yesil->sari->kirmizi
gradient, puruzsuz kenar, 13/13 dengeli dizilim. sysmon.py'den gercek veri okur."""
import os
import sys
import math
import pygame

try:
    import sysmon
except Exception:
    sysmon = None

WIDTH, HEIGHT = 1600, 900

_font_cache = {}


def _font(size, bold=True):
    key = (size, bold)
    if key not in _font_cache:
        _font_cache[key] = pygame.font.SysFont("DejaVu Sans", size, bold=bold)
    return _font_cache[key]


def temp_color(t):
    if t is None:
        return (60, 66, 60)
    if t < 55:
        return (60, 230, 90)
    if t < 70:
        return (245, 210, 60)
    return (235, 60, 40)


def _sm_grad_rgb(t):
    """0..1 -> yesil->sari->kirmizi YUMUSAK gecis."""
    t = max(0.0, min(1.0, t))
    if t < 0.5:
        f = t / 0.5
        return (int(58 + (242-58)*f), int(212 - (212-201)*f), int(110 - (110-76)*f))
    else:
        f = (t - 0.5) / 0.5
        return (int(242 + (235-242)*f), int(201 - (201-60)*f), int(76 - (76-40)*f))


def _arc_dots(surf, cx, cy, radius, deg_start, deg_end, width, color_fn):
    """Yayi sik dolu dairelerle ciz -> puruzsuz yuvarlak kenar."""
    if deg_end <= deg_start:
        return
    r = max(2, width // 2)
    arc_len = math.radians(deg_end - deg_start) * radius
    steps = max(3, int(arc_len / max(1, r * 0.55)))
    for i in range(steps + 1):
        f = i / steps
        deg = deg_start + (deg_end - deg_start) * f
        a = math.radians(deg)
        x = cx + radius * math.cos(a)
        y = cy + radius * math.sin(a)
        col = color_fn((deg - 150) / 240.0)
        pygame.draw.circle(surf, col, (int(x), int(y)), r)


def draw_card_gauge(surf, cx, cy, radius, frac):
    """240 derece halka, boyunca gradient renk, puruzsuz."""
    frac = max(0.0, min(1.0, frac))
    _arc_dots(surf, cx, cy, radius, 150, 390, 13, lambda t: (36, 45, 58))
    if frac <= 0.005:
        return
    end_deg = 150 + 240 * frac
    _arc_dots(surf, cx, cy, radius, 150, end_deg, 13, _sm_grad_rgb)


def draw(screen, d):
    W, H = screen.get_size()
    screen.fill((10, 12, 14))
    GREEN = (60, 230, 90)

    cpu_t = d.get("cpu_pkg"); cores = d.get("cores_max")
    gpu_e = d.get("gpu_edge"); gpu_j = d.get("gpu_junction"); gpu_m = d.get("gpu_mem")
    vrm = d.get("mb_vrm"); pch = d.get("mb_pch"); mbsys = d.get("mb_system")
    use = d.get("cpu_usage"); gpu_u = d.get("gpu_usage")
    ram = d.get("ram_pct")
    vram_u = d.get("gpu_vram_used"); vram_t = d.get("gpu_vram_total")
    frq = d.get("cpu_freq")
    cpu_p = d.get("cpu_power"); gpu_p = d.get("gpu_power")
    cfan = d.get("fan_cpu"); pump = d.get("fan_pump")
    gfan = d.get("gpu_fan_rpm")
    s1 = d.get("fan_sys1"); s2 = d.get("fan_sys2"); s3 = d.get("fan_sys3")
    s4 = d.get("fan_sys4"); s5 = d.get("fan_sys5"); s6 = d.get("fan_sys6")
    nd = d.get("net_down"); nu = d.get("net_up")

    def net_fmt(mb_s):
        if mb_s is None:
            return ("--", "Mbps", 0)
        mbit = mb_s * 8.388608
        return (f"{mbit:.1f}", "Mbps", mbit / 1000.0)
    nd_txt, nd_unit, nd_frac = net_fmt(nd)
    nu_txt, nu_unit, nu_frac = net_fmt(nu)

    vram_frac = (vram_u / vram_t) if (vram_u is not None and vram_t) else 0
    vram_txt = f"{vram_u:.1f}" if vram_u is not None else "--"

    def col(t): return temp_color(t)

    # SATIR 1 (13): sicakliklar + aktif fanlar + GHz
    bars_top = [
        ("CPU",  f"{cpu_t:.0f}"  if cpu_t is not None else "--", "C", (cpu_t/100.0)  if cpu_t else 0, col(cpu_t)),
        ("Çkrdk",f"{cores:.0f}"  if cores is not None else "--", "C", (cores/100.0)  if cores else 0, col(cores)),
        ("GPU",  f"{gpu_j:.0f}"  if gpu_j is not None else "--", "C", (gpu_j/110.0)  if gpu_j else 0, col(gpu_j)),
        ("GEdge",f"{gpu_e:.0f}"  if gpu_e is not None else "--", "C", (gpu_e/100.0)  if gpu_e else 0, col(gpu_e)),
        ("GMem", f"{gpu_m:.0f}"  if gpu_m is not None else "--", "C", (gpu_m/100.0)  if gpu_m else 0, col(gpu_m)),
        ("VRM",  f"{vrm:.0f}"    if vrm is not None else "--",   "C", (vrm/100.0)    if vrm else 0,   col(vrm)),
        ("PCH",  f"{pch:.0f}"    if pch is not None else "--",   "C", (pch/90.0)     if pch else 0,   col(pch)),
        ("Sys",  f"{mbsys:.0f}"  if mbsys is not None else "--", "C", (mbsys/90.0)   if mbsys else 0, col(mbsys)),
        ("CFan", f"{cfan:.0f}"   if cfan else "0",               "",  (cfan/3000.0)  if cfan else 0, GREEN),
        ("Pump", f"{pump:.0f}"   if pump else "0",               "",  (pump/3000.0)  if pump else 0, GREEN),
        ("GFan", f"{gfan:.0f}"   if gfan else "0",               "",  (gfan/3000.0)  if gfan else 0, GREEN),
        ("S1",   f"{s1:.0f}"     if s1 else "0",                 "",  (s1/3000.0)    if s1 else 0, GREEN),
        ("GHz",  f"{frq/1000:.1f}" if frq else "--",             "",  (frq/5700.0)   if frq else 0, GREEN),
    ]
    # SATIR 2 (13): kullanim + guc + pasif fanlar + ag
    bars_bot = [
        ("CPU%", f"{use:.0f}"    if use is not None else "--",   "%", (use/100.0)    if use is not None else 0, GREEN),
        ("GPU%", f"{gpu_u:.0f}"  if gpu_u is not None else "--", "%", (gpu_u/100.0)  if gpu_u is not None else 0, GREEN),
        ("RAM",  f"{ram:.0f}"    if ram is not None else "--",   "%", (ram/100.0)    if ram is not None else 0, GREEN),
        ("VRAM", vram_txt,                                       "G", vram_frac, GREEN),
        ("C-W",  f"{cpu_p:.0f}"  if cpu_p is not None else "--", "W", (cpu_p/250.0)  if cpu_p else 0, GREEN),
        ("G-W",  f"{gpu_p:.0f}"  if gpu_p is not None else "--", "W", (gpu_p/350.0)  if gpu_p else 0, GREEN),
        ("S2",   f"{s2:.0f}"     if s2 else "0",                 "",  (s2/3000.0)    if s2 else 0, GREEN),
        ("S3",   f"{s3:.0f}"     if s3 else "0",                 "",  (s3/3000.0)    if s3 else 0, GREEN),
        ("S4",   f"{s4:.0f}"     if s4 else "0",                 "",  (s4/3000.0)    if s4 else 0, GREEN),
        ("S5",   f"{s5:.0f}"     if s5 else "0",                 "",  (s5/3000.0)    if s5 else 0, GREEN),
        ("S6",   f"{s6:.0f}"     if s6 else "0",                 "",  (s6/3000.0)    if s6 else 0, GREEN),
        ("İndir",nd_txt, nd_unit, nd_frac, GREEN),
        ("Yükle",nu_txt, nu_unit, nu_frac, GREEN),
    ]

    margin = 20
    gap = 10
    half = H // 2

    def draw_row(bars, row_top, row_bottom):
        n = len(bars)
        card_w = (W - 2*margin - (n-1)*gap) // n
        card_top = row_top + 8
        card_h = (row_bottom - row_top) - 16
        # rakam fontu: TUM kartlarda ayni (en uzun "3267" sigacak sekilde)
        _gr = int(min(card_w, card_h) * 0.47)
        _gsize = int(card_w * 0.33)
        vfont = _font(_gsize)
        while vfont.size("3267")[0] > int(_gr * 1.5) and _gsize > 10:
            _gsize -= 1
            vfont = _font(_gsize)
        unitf = _font(max(13, int(card_w * 0.13)), bold=False)
        lblf = _font(max(14, int(card_w * 0.15)))

        for idx, (lbl, vtxt, unit, frac, color) in enumerate(bars):
            frac = max(0.0, min(1.0, frac))
            cx0 = margin + idx * (card_w + gap)
            ccx = cx0 + card_w // 2
            gcol = _sm_grad_rgb(frac)
            # kart
            pygame.draw.rect(screen, (22, 27, 34), (cx0, card_top, card_w, card_h), border_radius=14)
            pygame.draw.rect(screen, (35, 43, 54), (cx0, card_top, card_w, card_h), 1, border_radius=14)
            # gauge
            gauge_cy = card_top + int(card_h * 0.44)
            gauge_r = int(min(card_w, card_h) * 0.47)
            draw_card_gauge(screen, ccx, gauge_cy, gauge_r, frac)
            # rakam (halka ortasinda, ayni boyut)
            vs = vfont.render(vtxt, True, gcol)
            screen.blit(vs, (ccx - vs.get_width()//2, gauge_cy - vs.get_height()//2))
            # birim
            if unit:
                us = unitf.render(unit, True, (170, 182, 196))
                screen.blit(us, (ccx - us.get_width()//2, card_top + int(card_h*0.72)))
            # etiket
            ls = lblf.render(lbl, True, (210, 220, 232))
            screen.blit(ls, (ccx - ls.get_width()//2, card_top + int(card_h*0.86)))

    draw_row(bars_top, 0, half)
    draw_row(bars_bot, half, H)


def main():
    # mixer'siz init (ses aygiti acmasin -> LG OSD tetiklemesin)
    os.environ.setdefault("SDL_AUDIODRIVER", "dummy")
    pygame.display.init()
    pygame.font.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT), pygame.RESIZABLE)
    pygame.display.set_caption("Sistem Monitoru")
    clock = pygame.time.Clock()

    mon = sysmon.SysMonitor() if sysmon is not None else None
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key in (pygame.K_q, pygame.K_ESCAPE):
                    running = False

        if mon is not None:
            draw(screen, mon.snapshot())
        else:
            screen.fill((10, 12, 14))
            f = _font(36)
            screen.blit(f.render("sysmon yuklenemedi", True, (200, 80, 80)), (60, HEIGHT//2))
        pygame.display.flip()
        clock.tick(30)

    if mon is not None:
        mon.stop()
    pygame.quit()
    sys.exit()


if __name__ == "__main__":
    main()
