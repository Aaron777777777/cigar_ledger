#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
from pathlib import Path
from typing import Iterable, Tuple

from PIL import Image, ImageChops, ImageEnhance, ImageFilter, ImageOps, ImageDraw


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


def _clip_channel(mult: float = 1.0, add: float = 0.0):
    def fn(p: int, m: float = mult, a: float = add) -> int:
        return max(0, min(255, int(p * m + a)))
    return fn


def warm_grade(rgb: Image.Image, warmth: float = 0.12) -> Image.Image:
    """
    Subtle amber lift:
    - slightly more red
    - tiny lift in green
    - slightly less blue
    """
    r, g, b = rgb.split()
    r = r.point(_clip_channel(1.0 + 0.10 * warmth, 3.0 * warmth))
    g = g.point(_clip_channel(1.0 + 0.04 * warmth, 1.5 * warmth))
    b = b.point(_clip_channel(1.0 - 0.10 * warmth, -2.0 * warmth))
    return Image.merge("RGB", (r, g, b))


def polish_object(
    obj: Image.Image,
    sharpen_percent: int = 138,
    contrast: float = 1.06,
    saturation: float = 1.03,
    brightness: float = 0.99,
    warmth: float = 0.12,
) -> Image.Image:
    obj = obj.convert("RGBA")
    alpha = obj.getchannel("A")

    rgb = obj.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(contrast)
    rgb = ImageEnhance.Color(rgb).enhance(saturation)
    rgb = ImageEnhance.Brightness(rgb).enhance(brightness)
    rgb = warm_grade(rgb, warmth=warmth)
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=1.1, percent=sharpen_percent, threshold=2))

    polished = rgb.convert("RGBA")
    polished.putalpha(alpha)
    return polished


def add_ambient_glow(
    base: Image.Image,
    obj: Image.Image,
    pos: Tuple[int, int],
    blur: int = 34,
    opacity: int = 34,
    expand: int = 22,
    y_offset: int = 6,
    color: Tuple[int, int, int] = (28, 16, 8),
) -> Image.Image:
    x, y = pos
    alpha = obj.getchannel("A")

    glow_mask = Image.new("L", (alpha.width + expand * 2, alpha.height + expand * 2), 0)
    glow_mask.paste(alpha, (expand, expand))
    glow_mask = glow_mask.filter(ImageFilter.GaussianBlur(blur))
    glow_alpha = glow_mask.point(lambda p, o=opacity: max(0, min(255, int(p * o / 255))))

    glow_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    glow_obj = Image.new("RGBA", glow_mask.size, color + (0,))
    glow_obj.putalpha(glow_alpha)

    gx = x - expand
    gy = y - expand + y_offset
    glow_layer.paste(glow_obj, (gx, gy), glow_obj)
    return Image.alpha_composite(base, glow_layer)


def add_soft_shadow(
    base: Image.Image,
    obj: Image.Image,
    pos: Tuple[int, int],
    blur: int = 20,
    opacity: int = 84,
    x_offset: int = 0,
    y_offset: int = 20,
    color: Tuple[int, int, int] = (8, 5, 3),
) -> Image.Image:
    x, y = pos
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    alpha = obj.getchannel("A")

    shadow_obj = Image.new("RGBA", obj.size, color + (0,))
    shadow_obj.putalpha(alpha.point(lambda p, o=opacity: max(0, min(255, int(p * o / 255)))))

    shadow.paste(shadow_obj, (x + x_offset, y + y_offset), shadow_obj)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    return Image.alpha_composite(base, shadow)


def add_floor_reflection(
    base: Image.Image,
    obj: Image.Image,
    pos: Tuple[int, int],
    max_height: int = 80,
    opacity: int = 26,
    gap: int = 10,
) -> Image.Image:
    x, y = pos
    refl = ImageOps.flip(obj)
    scale = min(1.0, max_height / max(1, refl.height))
    refl = refl.resize(
        (max(1, int(refl.width * scale)), max(1, int(refl.height * scale))),
        Image.LANCZOS,
    )

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


def add_canvas_vignette(
    base: Image.Image,
    strength: int = 42,
    inset_ratio: float = 0.09,
    color: Tuple[int, int, int] = (10, 6, 2),
) -> Image.Image:
    cw, ch = base.size

    center_mask = Image.new("L", (cw, ch), 0)
    draw = ImageDraw.Draw(center_mask)
    inset = int(min(cw, ch) * inset_ratio)
    draw.ellipse((inset, inset, cw - inset, ch - inset), fill=255)

    blur_radius = int(min(cw, ch) * 0.17)
    center_mask = center_mask.filter(ImageFilter.GaussianBlur(blur_radius))

    edge_mask = ImageChops.invert(center_mask)
    edge_alpha = edge_mask.point(lambda p, s=strength: max(0, min(255, int(p * s / 255))))

    overlay = Image.new("RGBA", (cw, ch), color + (0,))
    overlay.putalpha(edge_alpha)
    return Image.alpha_composite(base, overlay)


def place_on_canvas(
    obj: Image.Image,
    canvas_size: Tuple[int, int] = (900, 900),
    fill_ratio: float = 0.72,
    glow: bool = True,
    shadow: bool = True,
    reflection: bool = False,
    vignette: bool = True,
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

    if glow:
        out = add_ambient_glow(out, obj, (x, y))

    if shadow:
        out = add_soft_shadow(out, obj, (x, y))

    out.paste(obj, (x, y), obj)

    if reflection:
        out = add_floor_reflection(out, obj, (x, y))

    if vignette:
        out = add_canvas_vignette(out)

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
    with_glow: bool,
    with_shadow: bool,
    with_reflection: bool,
    with_vignette: bool,
) -> None:
    img = Image.open(src).convert("RGBA")
    img = trim_transparent(img, padding=8)
    img = polish_object(img)
    img = place_on_canvas(
        img,
        canvas_size=canvas_size,
        fill_ratio=fill_ratio,
        glow=with_glow,
        shadow=with_shadow,
        reflection=with_reflection,
        vignette=with_vignette,
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
    parser = argparse.ArgumentParser(
        description="Premium cigar image polish pipeline. Safe default: process inbox/raw images, not live finished assets."
    )
    parser.add_argument("--input", default="assets/cigars_inbox", help="Input folder of cigar images")
    parser.add_argument("--output", default="assets/cigars_polished", help="Output folder for polished images")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite the input folder after making a backup")
    parser.add_argument("--allow-live-input", action="store_true", help="Allow processing assets/cigars directly (not recommended)")
    parser.add_argument("--canvas", default="900x900", help="Canvas size, e.g. 900x900")
    parser.add_argument("--fill-ratio", type=float, default=0.72, help="How tall the cigar should appear on the canvas")
    parser.add_argument("--no-glow", action="store_true", help="Disable ambient glow")
    parser.add_argument("--no-shadow", action="store_true", help="Disable soft shadow")
    parser.add_argument("--no-vignette", action="store_true", help="Disable canvas vignette")
    parser.add_argument("--reflection", action="store_true", help="Enable subtle bottom reflection")
    args = parser.parse_args()

    input_dir = Path(args.input)
    if not input_dir.exists():
        raise SystemExit(f"Input folder not found: {input_dir}")

    live_dir = (Path.cwd() / "assets" / "cigars").resolve()
    if input_dir.resolve() == live_dir and not args.allow_live_input:
        raise SystemExit(
            "Refusing to process live assets/cigars directly.\n"
            "Use assets/cigars_inbox or assets/cigars_raw instead.\n"
            "Pass --allow-live-input only if you truly intend a live rebuild."
        )

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
            with_glow=not args.no_glow,
            with_shadow=not args.no_shadow,
            with_reflection=args.reflection,
            with_vignette=not args.no_vignette,
        )
        print(f"Processed: {src.name}")

    print(f"\nDone. Output folder: {output_dir}")
    if not args.overwrite:
        print("Originals were left untouched.")


if __name__ == "__main__":
    main()