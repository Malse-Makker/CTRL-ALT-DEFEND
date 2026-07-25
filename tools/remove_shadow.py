#!/usr/bin/env python3
"""Achtergrond én slagschaduw weghalen bij een Retro-Diffusion-sprite.

Gebruik dit op de 96x96 VOOR het downscalen. Na het downscalen deelt de schaduw zijn
kleur met het object zelf, en dan beschadigt filteren op kleur de sprite.

Werking: flood-fill vanaf de rand, waarbij elke kleur die vaak genoeg in de buitenste
rand voorkomt als achtergrond geldt (dus ook de schaduwtint). De donkere outline die het
stijl-recept voorschrijft houdt de fill buiten het object.

Gebruik:  python3 tools/remove_shadow.py art/towers/ceo_3.png [meer.png ...]
Schrijft <naam>_c.png ernaast. Voor sprites zonder slagschaduw volstaat remove_bg.py.
"""
import sys
from collections import deque, Counter

from PIL import Image

def clean(src, dst):
    im = Image.open(src).convert("RGBA"); px = im.load(); W, H = im.size
    bg = px[0, 0][:3]
    # Schaduwtinten: kleuren die in de buitenste rand voorkomen naast de achtergrond.
    edge = Counter()
    for x in range(W):
        for y in (0, 1, H - 2, H - 1):
            edge[px[x, y][:3]] += 1
    for y in range(H):
        for x in (0, 1, W - 2, W - 1):
            edge[px[x, y][:3]] += 1
    allow = {c for c, n in edge.items() if n >= 12}
    seen = [[False] * H for _ in range(W)]
    q = deque()
    for x in range(W):
        q.append((x, 0)); q.append((x, H - 1))
    for y in range(H):
        q.append((0, y)); q.append((W - 1, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= W or y >= H or seen[x][y]:
            continue
        if px[x, y][:3] not in allow:
            continue
        seen[x][y] = True
        q.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    n = 0
    for x in range(W):
        for y in range(H):
            if seen[x][y]:
                px[x, y] = (0, 0, 0, 0); n += 1
    im.save(dst)
    return bg, sorted(allow), n

for src in sys.argv[1:]:
    dst = src.replace(".png", "_c.png")
    bg, allow, n = clean(src, dst)
    print(f"{src}: bg={bg} allow={allow} -> {n} px weg")
