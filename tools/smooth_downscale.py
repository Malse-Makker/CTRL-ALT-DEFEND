"""Gladde downscale van Blender-renders naar sprite-formaat.

Anders dan downscale.py (pixel-perfect, meest voorkomende kleur per blok) gebruikt dit
LANCZOS-resampling: dat hoort bij 3D-renders, niet bij pixel-art.

Snijdt eerst de lege rand weg zodat elk icoon het frame even goed vult — de renders zijn
transparant, dus de alpha-kanaal-bounding-box is de vorm van het object.

    python3 tools/smooth_downscale.py 128 art/towers art/blender_out/*.png

De 512px-renders blijven staan: schrijven gebeurt altijd naar de opgegeven doelmap.
"""
import os
import sys
from PIL import Image

PAD = 0.04  # marge rondom het object, als fractie van de doelgrootte


def process(path: str, size: int, outdir: str) -> None:
    im = Image.open(path).convert("RGBA")
    bbox = im.getbbox()
    if bbox is None:
        print(f"{path}: helemaal leeg, overgeslagen")
        return
    im = im.crop(bbox)

    # vierkant maken met het object gecentreerd, daarna pas schalen
    side = max(im.size)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(im, ((side - im.width) // 2, (side - im.height) // 2))

    inner = max(1, round(size * (1.0 - 2 * PAD)))
    small = canvas.resize((inner, inner), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(small, ((size - inner) // 2, (size - inner) // 2))
    dest = os.path.join(outdir, os.path.basename(path))
    out.save(dest)
    print(f"{dest}: {bbox[2]-bbox[0]}x{bbox[3]-bbox[1]} -> {size}x{size}")


if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit("gebruik: smooth_downscale.py <grootte> <doelmap> <png> [png ...]")
    target = int(sys.argv[1])
    dest_dir = sys.argv[2]
    os.makedirs(dest_dir, exist_ok=True)
    for p in sys.argv[3:]:
        process(p, target, dest_dir)
