#!/usr/bin/env python3
"""Maakt de effen achtergrond van een sprite transparant.

Flood-fill vanaf de rand, zodat kleuren die toevallig ook in de sprite zitten
(bijv. grijstinten in een koffieautomaat) blijven staan.

Gebruik:  python3 tools/remove_bg.py art/towers/coffee.png [meer.png ...]
"""
import sys
from collections import deque

from PIL import Image

TOLERANCE = 30


def remove_bg(path: str, tol: int = TOLERANCE) -> str:
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()
    bg = px[0, 0][:3]

    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))

    def is_bg(c):
        return all(abs(c[i] - bg[i]) <= tol for i in range(3))

    cleared = 0
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h:
            continue
        idx = y * w + x
        if seen[idx]:
            continue
        seen[idx] = 1
        r, g, b, a = px[x, y]
        if not is_bg((r, g, b)):
            continue
        px[x, y] = (r, g, b, 0)
        cleared += 1
        q.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])

    im.save(path)
    pct = 100.0 * cleared / (w * h)
    return f"{path}: {cleared}/{w*h} pixels transparant ({pct:.0f}%)"


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    for p in sys.argv[1:]:
        print(remove_bg(p))
