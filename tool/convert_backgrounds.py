"""Convierte las fotos de fondo a WebP para la app (no se empaqueta).

Uso:
    python -I tool/convert_backgrounds.py <carpeta_origen> [--pylib <ruta>]

Lee assets/backgrounds/backgrounds.json; para cada fondo con "source"
busca ese archivo en <carpeta_origen> y escribe:
  - assets/backgrounds/<id>.webp        (lado corto 1440 px, calidad 78)
  - assets/backgrounds/thumbs/<id>.webp (miniatura 360x240, calidad 70)
Los panoramas más anchos que 2:1 se recortan al centro.
Al final muestra el tamaño total.
"""

import json
import os
import sys

args = sys.argv[1:]
if "--pylib" in args:
    i = args.index("--pylib")
    sys.path.insert(0, args[i + 1])
    del args[i : i + 2]

from PIL import Image, ImageOps  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "backgrounds")
SHORT_SIDE = 1440
MAX_RATIO = 2.0


def crop_ratio(img):
    w, h = img.size
    if w / h > MAX_RATIO:
        nw = int(h * MAX_RATIO)
        left = (w - nw) // 2
        return img.crop((left, 0, left + nw, h))
    if h / w > MAX_RATIO:
        nh = int(w * MAX_RATIO)
        top = (h - nh) // 2
        return img.crop((0, top, w, top + nh))
    return img


def main():
    if not args:
        print(__doc__)
        sys.exit(1)
    src_dir = args[0]
    with open(os.path.join(OUT, "backgrounds.json"), encoding="utf-8") as f:
        catalog = json.load(f)
    os.makedirs(os.path.join(OUT, "thumbs"), exist_ok=True)
    total_in = total_out = 0
    for bg in catalog["backgrounds"]:
        source = bg.get("source")
        if not source:
            continue
        path = os.path.join(src_dir, source)
        if not os.path.exists(path):
            path = os.path.join(ROOT, source)
        total_in += os.path.getsize(path)
        img = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
        img = crop_ratio(img)
        w, h = img.size
        scale = SHORT_SIDE / min(w, h)
        if scale < 1:
            img = img.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
        out = os.path.join(OUT, bg["id"] + ".webp")
        img.save(out, "WEBP", quality=78, method=6)
        thumb = ImageOps.fit(img, (360, 240), Image.LANCZOS)
        thumb_out = os.path.join(OUT, "thumbs", bg["id"] + ".webp")
        thumb.save(thumb_out, "WEBP", quality=70, method=6)
        size = os.path.getsize(out) + os.path.getsize(thumb_out)
        total_out += size
        print(f"{bg['id']:<14} {img.size[0]}x{img.size[1]}  {size / 1024:.0f} KB")
    print(f"Total: {total_in / 1e6:.1f} MB -> {total_out / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
