#!/usr/bin/env python3
"""Pixel-perfecte downscale (k-centroid-achtig) voor pixel-art sprites.

Genereer sprites groot (bijv. 96x96) voor detail en schaal ze hiermee terug naar
de doelgrootte. Per doelpixel wordt de meest voorkomende kleur in het bronblok
gekozen, zodat de pixels hard blijven (geen blur zoals bij gewoon resizen).

Gebruik:  python3 tools/downscale.py 48 art/enemies/tank.png [meer.png ...]
"""
import sys
from collections import Counter

from PIL import Image


def downscale(path: str, target: int) -> str:
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    if w == target and h == target:
        return f"{path}: al {target}x{target}, overgeslagen"
    src = im.load()
    out = Image.new("RGBA", (target, target))
    dst = out.load()
    bx, by = w / target, h / target

    for ty in range(target):
        for tx in range(target):
            x0, x1 = int(tx * bx), max(int(tx * bx) + 1, int((tx + 1) * bx))
            y0, y1 = int(ty * by), max(int(ty * by) + 1, int((ty + 1) * by))
            counts = Counter()
            for y in range(y0, min(y1, h)):
                for x in range(x0, min(x1, w)):
                    counts[src[x, y]] += 1
            dst[tx, ty] = counts.most_common(1)[0][0]

    out.save(path)
    return f"{path}: {w}x{h} -> {target}x{target}"


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    size = int(sys.argv[1])
    for p in sys.argv[2:]:
        print(downscale(p, size))
