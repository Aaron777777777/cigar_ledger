#!/usr/bin/env python3
from __future__ import annotations

import argparse
import math
import shutil
from pathlib import Path
from typing import Iterable, Tuple

from PIL import Image, ImageChops, ImageEnhance, ImageFilter, ImageOps


SUPPORTED_EXTS = {".png", ".webp", ".jpg", ".jpeg"}


def iter_images(folder: Path) -> Iterable[Path]:
    for p in sorted(folder.iterdir()):
        if p.is_file() and p.suffix.lower() in SUPPORTED_EXTS:
            yield p


def trim_transparent(img: Image.Image, padding: int = 8) -> Image.Image:
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    alpha = img.getchannel("A")
    bbox = alpha.getbbox()
    if not bbox:
        return img
    x1, y1, x2, y2 = bbox
    x1 = max(0, x1 - padding)
    y1 = max(0, y1 - padding)
    x2 = min(img.width, x2 + padding)
    y2 = min(img.height, y2 + padding)
    return img.crop((x1, y1, x2, y2))


def add_soft_shadow(
    base: Image.Image,
    obj: Image.Image,
    pos: Tuple[int, int],
    blur: int = 18,
    opacity: int = 70,
    x_offset: int = 0,
    y_offset: int = 16,
) -> Image.Image:
    x, y = pos
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    alpha = obj.getchannel("A")
    shadow_obj = Image.new("RGBA", obj.size, (0, 0, 0, opacity))
    shadow_obj.putalpha(alpha)
    shadow.paste(shadow_obj, (x + x_offset, y + y_offset), shadow_obj)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    return Image.alpha_composite(base, shadow)


def add_floor_reflection(
    base: Image.Image,
    obj: Image.Image,
    pos: Tuple[int, int],
    max_height: int = 90,
    opacity: int = 42,
    gap: int = 10,
) -> Image.Image:
    x, y = pos
    refl = ImageOps.flip(obj)
    scale = min(1.0, max_height / max(1, refl.height))
    refl = refl.resize((max(1, int(refl.width * scale)), max(1, int(refl.height * scale))), Image.LANCZOS)

    alpha = refl.getchannel("A")
    fade = Image.new("L", refl.size, 0)
    for yy in range(refl.height):
        a = int(opacity * max(0, 1 - yy / max(1, refl.height - 1)) ** 1.7)
        for xx in range(refl.width):
            fade.putpixel((xx, yy), a)
    alpha = ImageChops.multiply(alpha, fade)
    refl.putalpha(alpha)

    out = base.copy()
    out.paste(refl, (x, y + obj.height + gap), refl)
    return out


def polish_object(
    obj: Image.Image,
    sharpen_percent: int = 118,
    contrast: float = 1.04,
    saturation: float = 1.02,
    brightness: float = 1.01,
) -> Image.Image:
    obj = obj.convert("RGBA")
    rgb = obj.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(contrast)
    rgb = ImageEnhance.Color(rgb).enhance(saturation)
    rgb = ImageEnhance.Brightness(rgb).enhance(brightness)
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=1.0, percent=sharpen_percent, threshold=2))
    alpha = obj.getchannel("A")
    polished = rgb.convert("RGBA")
    polished.putalpha(alpha)
    return polished


def place_on_canvas(
    obj: Image.Image,
    canvas_size: Tuple[int, int] = (900, 900),
    fill_ratio: float = 0.72,
    shadow: bool = True,
    reflection: bool = False,
) -> Image.Image:
    cw, ch = canvas_size
    out = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))

    max_w = int(cw * 0.42)
    max_h = int(ch * fill_ratio)
    scale = min(max_w / max(1, obj.width), max_h / max(1, obj.height))
    nw = max(1, int(obj.width * scale))
    nh = max(1, int(obj.height * scale))
    obj = obj.resize((nw, nh), Image.LANCZOS)

    x = (cw - nw) // 2
    y = int(ch * 0.10)

    if shadow:
        out = add_soft_shadow(out, obj, (x, y), blur=16, opacity=62, y_offset=18)
    out.paste(obj, (x, y), obj)

    if reflection:
        out = add_floor_reflection(out, obj, (x, y), max_height=80, opacity=36, gap=10)

    return out


def maybe_backup_folder(folder: Path) -> Path:
    backup = folder.parent / f"{folder.name}_original_backup"
    if backup.exists():
        return backup
    shutil.copytree(folder, backup)
    return backup


def process_file(
    src: Path,
    dst: Path,
    canvas_size: Tuple[int, int],
    fill_ratio: float,
    with_shadow: bool,
    with_reflection: bool,
) -> None:
    img = Image.open(src).convert("RGBA")
    img = trim_transparent(img, padding=8)
    img = polish_object(img)
    img = place_on_canvas(
        img,
        canvas_size=canvas_size,
        fill_ratio=fill_ratio,
        shadow=with_shadow,
        reflection=with_reflection,
    )

    dst.parent.mkdir(parents=True, exist_ok=True)
    ext = dst.suffix.lower()
    if ext in {".jpg", ".jpeg"}:
        bg = Image.new("RGB", img.size, (0, 0, 0))
        bg.paste(img, mask=img.getchannel("A"))
        bg.save(dst, quality=95)
    else:
        img.save(dst)


def main() -> None:
    parser = argparse.ArgumentParser(description="Batch polish cigar packshot images without overwriting originals by default.")
    parser.add_argument("--input", default="assets/cigars", help="Input folder of cigar images")
    parser.add_argument("--output", default="assets/cigars_polished", help="Output folder for polished images")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite the input folder after making a backup")
    parser.add_argument("--canvas", default="900x900", help="Canvas size, e.g. 900x900")
    parser.add_argument("--fill-ratio", type=float, default=0.72, help="How tall the cigar should appear on the canvas")
    parser.add_argument("--no-shadow", action="store_true", help="Disable soft shadow")
    parser.add_argument("--reflection", action="store_true", help="Enable subtle bottom reflection")
    args = parser.parse_args()

    input_dir = Path(args.input)
    if not input_dir.exists():
        raise SystemExit(f"Input folder not found: {input_dir}")

    try:
        cw, ch = [int(x) for x in args.canvas.lower().split("x")]
    except Exception:
        raise SystemExit("Canvas must be in the form WIDTHxHEIGHT, e.g. 900x900")

    if args.overwrite:
        backup = maybe_backup_folder(input_dir)
        print(f"Backup created at: {backup}")
        output_dir = input_dir
    else:
        output_dir = Path(args.output)
        output_dir.mkdir(parents=True, exist_ok=True)

    files = list(iter_images(input_dir))
    if not files:
        raise SystemExit(f"No supported images found in: {input_dir}")

    for src in files:
        dst = output_dir / src.name
        process_file(
            src=src,
            dst=dst,
            canvas_size=(cw, ch),
            fill_ratio=args.fill_ratio,
            with_shadow=not args.no_shadow,
            with_reflection=args.reflection,
        )
        print(f"Processed: {src.name}")

    print(f"\nDone. Output folder: {output_dir}")
    if not args.overwrite:
        print("Originals were left untouched.")


if __name__ == "__main__":
    main()
