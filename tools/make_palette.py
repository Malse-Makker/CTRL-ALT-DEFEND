#!/usr/bin/env python3
"""Genereert art/palette.png: het vaste huisstijl-palet voor alle sprites.

Dit bestand wordt als `input_palette` meegegeven aan Retro Diffusion, zodat elke
sprite exact dezelfde kleuren gebruikt. Aanpassen = huisstijl aanpassen.
"""
from PIL import Image

# Kantoor-huisstijl. Bewust beperkt: 1 donkere outline, neutrale grijzen,
# en per rol een eigen accentkleur (licht / basis / donker).
PALETTE = [
    # outline + neutraal
    "#14161c", "#23262f", "#3c4049", "#565b66",
    "#7b818e", "#a9aeb8", "#d7dae0", "#f2f4f7",
    # huid
    "#e8b796", "#c98d6b", "#8a5a3f",
    # blauw — mail / jouw kant
    "#7fb4f0", "#3f7fd6", "#2a5aa0",
    # groen — filter / veilig
    "#8fd6a8", "#4faa78", "#2f7a54",
    # rood — CEO / urgent
    "#f08b84", "#d4564f", "#a03530",
    # oranje — waarschuwing
    "#e8a55c", "#e0813c", "#b06520",
    # geel — notificatie
    "#f2dc82", "#e8c84a", "#b89a2c",
    # paars — scrum / kletskous
    "#c2a2e8", "#9a72c8", "#6f4d99",
]

SWATCH = 16


def main() -> None:
    cols = 8
    rows = (len(PALETTE) + cols - 1) // cols
    im = Image.new("RGB", (cols * SWATCH, rows * SWATCH), PALETTE[0])
    px = im.load()
    for i, hex_col in enumerate(PALETTE):
        r = int(hex_col[1:3], 16)
        g = int(hex_col[3:5], 16)
        b = int(hex_col[5:7], 16)
        cx, cy = (i % cols) * SWATCH, (i // cols) * SWATCH
        for y in range(cy, cy + SWATCH):
            for x in range(cx, cx + SWATCH):
                px[x, y] = (r, g, b)
    im.save("art/palette.png")
    print(f"art/palette.png geschreven — {len(PALETTE)} kleuren, {im.size[0]}x{im.size[1]}")


if __name__ == "__main__":
    main()
