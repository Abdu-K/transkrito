"""Generates app icons from design tokens: pillar mark on icy gradient.
Outputs windows/Transkrito/Assets/transkrito.ico, tray PNGs, and macos/Assets/AppIcon.png (1024).
Run: python design/make-icon.py
"""
import json, math, os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = json.load(open(os.path.join(ROOT, "design", "tokens.json"), encoding="utf-8"))

def hex_rgb(h):
    h = h.lstrip("#"); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

BG_TOP = hex_rgb(T["color"]["bg"]["top"]["hex"])
BG_BOTTOM = hex_rgb(T["color"]["bg"]["bottom"]["hex"])
DEEP = hex_rgb(T["color"]["bg"]["deep"]["hex"])
GLASS_TOP = hex_rgb(T["color"]["pillar"]["glassFillTop"]["hex"])
GLASS_BOTTOM = hex_rgb(T["color"]["pillar"]["glassFillBottom"]["hex"])
ACCENT = hex_rgb(T["color"]["accent"]["base"]["hex"])
ACCENT_ICE = hex_rgb(T["color"]["accent"]["ice"]["hex"])
INK = hex_rgb(T["color"]["ink"]["primary"]["hex"])
COUNT = 7  # icon uses a reduced pillar count; same envelope as tokens

def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def envelope(i, n):
    d = abs(i - (n - 1) / 2)
    return max(0.15, math.cos(math.pi * d / (n - 1)) ** 2)

def render(size, rounded=True, transparent_bg=False, mono=None):
    s = size
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if not transparent_bg:
        for y in range(s):
            d.line([(0, y), (s, y)], fill=lerp(BG_TOP, BG_BOTTOM, y / s) + (255,))
        glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        r = int(s * 0.55)
        gd.ellipse([s / 2 - r, s * 0.32 - r, s / 2 + r, s * 0.32 + r], fill=DEEP + (int(255 * 0.18),))
        glow = glow.filter(ImageFilter.GaussianBlur(s * 0.18))
        img = Image.alpha_composite(img, glow)
        d = ImageDraw.Draw(img)
    # pillars
    w = s * 0.075; gap = s * 0.055
    total = COUNT * w + (COUNT - 1) * gap
    x0 = (s - total) / 2
    maxh = s * 0.52; minh = s * 0.10
    for i in range(COUNT):
        h = minh + (maxh - minh) * envelope(i, COUNT)
        x = x0 + i * (w + gap)
        y = s / 2 - h / 2
        if mono:
            fill = mono
        else:
            fill = lerp(GLASS_TOP, GLASS_BOTTOM, 0.5) + (255,)
        d.rounded_rectangle([x, y, x + w, y + h], radius=w / 2, fill=fill)
        if not mono:
            d.rounded_rectangle([x + w * 0.22, y + w * 0.3, x + w * 0.5, y + h * 0.4], radius=w * 0.14, fill=(255, 255, 255, 120))
    if rounded and not transparent_bg:
        mask = Image.new("L", (s, s), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.22), fill=255)
        img.putalpha(mask)
    return img

def render_small(size):
    s = size
    img = Image.new("RGBA", (s, s), BG_TOP + (255,))
    d = ImageDraw.Draw(img)
    n = 5
    w = max(1, round(s * 0.11)); gap = max(1, round(s * 0.09))
    total = n * w + (n - 1) * gap
    x0 = (s - total) / 2
    for i in range(n):
        h = s * (0.3 + 0.5 * envelope(i, n))
        x = x0 + i * (w + gap)
        d.rounded_rectangle([x, s / 2 - h / 2, x + w, s / 2 + h / 2], radius=w / 2, fill=ACCENT_ICE + (255,))
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, s - 1, s - 1], radius=max(2, int(s * 0.2)), fill=255)
    img.putalpha(mask)
    return img

def main():
    win_assets = os.path.join(ROOT, "windows", "Transkrito", "Assets")
    mac_assets = os.path.join(ROOT, "macos", "Assets")
    os.makedirs(win_assets, exist_ok=True); os.makedirs(mac_assets, exist_ok=True)
    sizes = [16, 24, 32, 48, 64, 128, 256]
    # Small sizes get a simplified 5-bar mark on solid navy so the title bar tile stays legible.
    frames = [(render_small(z) if z <= 32 else render(1024).resize((z, z), Image.LANCZOS)) for z in sizes]
    frames[-1].save(os.path.join(win_assets, "transkrito.ico"), format="ICO",
                    sizes=[(z, z) for z in sizes], append_images=frames[:-1])
    render(1024).save(os.path.join(mac_assets, "AppIcon.png"))
    # Tray icons: idle (ink), listening (accent), transcribing (accent, dimmed)
    for name, color in [("tray-idle", INK + (255,)), ("tray-listening", ACCENT + (255,)), ("tray-transcribing", ACCENT + (150,))]:
        im = render(256, transparent_bg=True, mono=color).resize((32, 32), Image.LANCZOS)
        im.save(os.path.join(win_assets, f"{name}.png"))
        im.save(os.path.join(win_assets, f"{name}.ico"), format="ICO", sizes=[(32, 32), (16, 16)])
    print("icons written")

if __name__ == "__main__":
    main()
