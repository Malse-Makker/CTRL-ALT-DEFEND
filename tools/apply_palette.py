"""Trek alle sprites naar hetzelfde huisstijl-palet.

De sprites zijn los van elkaar gegenereerd en gebruiken daardoor elk hun eigen tinten;
dit mapt elke pixel naar de dichtstbijzijnde kleur uit art/palette.png. De vergelijking
gebeurt in CIE Lab, niet in RGB: in RGB liggen bijvoorbeeld donkerrood en donkerbruin
dichter bij elkaar dan het oog vindt, waardoor je vlakken in elkaar ziet lopen.

Alpha blijft ongemoeid, dus transparante randen en schaduwen overleven het.

    python3 tools/apply_palette.py art/palette.png art/towers_pal art/towers/*.png

Doet niets aan perspectief of detailniveau — alleen kleur.
"""
import os
import sys
from PIL import Image

ALPHA_FLOOR = 8   # daaronder telt een pixel als transparant en laten we hem met rust


def _srgb_to_lab(rgb):
    def lin(c):
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (lin(float(c)) for c in rgb)
    # sRGB D65 -> XYZ, genormaliseerd op het witpunt
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = (0.2126 * r + 0.7152 * g + 0.0722 * b)
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883

    def f(t):
        return t ** (1.0 / 3.0) if t > 0.008856 else (7.787 * t + 16.0 / 116.0)

    fx, fy, fz = f(x), f(y), f(z)
    return (116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


def load_palette(path):
    im = Image.open(path).convert("RGB")
    cols = sorted(set(im.getdata()))
    return [(c, _srgb_to_lab(c)) for c in cols]


def convert(path, palette, outdir, cache):
    im = Image.open(path).convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < ALPHA_FLOOR:
                continue
            key = (r, g, b)
            hit = cache.get(key)
            if hit is None:
                l1, a1, b1 = _srgb_to_lab(key)
                hit = min(palette, key=lambda p: (l1 - p[1][0]) ** 2
                          + (a1 - p[1][1]) ** 2 + (b1 - p[1][2]) ** 2)[0]
                cache[key] = hit
            px[x, y] = (hit[0], hit[1], hit[2], a)
    dest = os.path.join(outdir, os.path.basename(path))
    im.save(dest)
    return dest


if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit("gebruik: apply_palette.py <palette.png> <doelmap> <png> [png ...]")
    pal = load_palette(sys.argv[1])
    dest_dir = sys.argv[2]
    os.makedirs(dest_dir, exist_ok=True)
    shared = {}
    for p in sys.argv[3:]:
        print(convert(p, pal, dest_dir, shared))
    print(f"{len(sys.argv) - 3} sprites, {len(shared)} unieke kleuren -> {len(pal)} paletkleuren")
