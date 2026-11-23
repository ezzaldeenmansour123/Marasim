#!/usr/bin/env python3
"""Builds the MARASIM launcher icon (PIL) into an Android res dir.

Uses the supplied emblem assets/logo.png (gold globe on a column with
laurel, on dark blue — no text inside the emblem): it is resized to each
mipmap density on a matching deep-petroleum-blue background. If the logo
is missing, a navy/gold fallback emblem is drawn so the build never breaks.
Usage: python3 tools/make_icon.py android/app/src/main/res
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

NAVY = (11, 34, 57, 255)
GOLD = (198, 161, 91, 255)
GOLD_LIGHT = (222, 190, 130, 255)


def fallback_icon(size):
    img = Image.new('RGBA', (size, size), NAVY)
    d = ImageDraw.Draw(img)
    s = size / 100.0
    # gold globe
    d.ellipse([28 * s, 14 * s, 72 * s, 58 * s], outline=GOLD, width=max(2, int(2 * s)))
    d.ellipse([36 * s, 22 * s, 64 * s, 50 * s], fill=GOLD)
    # column
    d.rectangle([44 * s, 58 * s, 56 * s, 82 * s], fill=GOLD_LIGHT)
    d.rectangle([38 * s, 82 * s, 62 * s, 86 * s], fill=GOLD)
    # laurel arcs
    d.arc([14 * s, 30 * s, 86 * s, 92 * s], start=200, end=340, fill=GOLD, width=max(2, int(2 * s)))
    return img


def draw_icon(size, logo_path):
    img = Image.new('RGBA', (size, size), NAVY)
    try:
        logo = Image.open(logo_path).convert('RGBA')
    except Exception as exc:  # noqa: BLE001 - fallback must never break the build
        print(f'logo not usable ({exc}); using fallback emblem')
        return fallback_icon(size)
    # The emblem is square on a dark-blue background; cover the tile.
    logo = logo.resize((size, size), Image.LANCZOS)
    img.alpha_composite(logo)
    return img


def main():
    if len(sys.argv) < 2:
        print('usage: make_icon.py <res-dir>', file=sys.stderr)
        sys.exit(2)
    res = Path(sys.argv[1])
    logo = Path(__file__).resolve().parent.parent / 'assets' / 'logo.png'
    for name, size in SIZES.items():
        out = res / name
        out.mkdir(parents=True, exist_ok=True)
        draw_icon(size, logo).save(out / 'ic_launcher.png')
        print(f'{name}/ic_launcher.png {size}x{size}')


if __name__ == '__main__':
    main()
