#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


SUPPORTED = {".png", ".webp"}


def cleanup_white_fringe(
    img: Image.Image,
    white_threshold: int = 235,
    alpha_limit: int = 210,
    neighbor_alpha_limit: int = 25,
    protect_core_alpha: int = 245,
) -> Image.Image:
    rgba = np.array(img.convert("RGBA"), dtype=np.uint8)
    rgb = rgba[:, :, :3]
    alpha = rgba[:, :, 3]

    is_bright = (
        (rgb[:, :, 0] >= white_threshold)
        & (rgb[:, :, 1] >= white_threshold)
        & (rgb[:, :, 2] >= white_threshold)
    )

    candidate_alpha = (alpha > 0) & (alpha <= alpha_limit)

    pad = np.pad(alpha, 1, mode="constant", constant_values=0)
    neighbors = []
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue
            neighbors.append(
                pad[1 + dy:1 + dy + alpha.shape[0], 1 + dx:1 + dx + alpha.shape[1]]
            )
    neighbor_stack = np.stack(neighbors, axis=0)
    touches_transparent_edge = np.any(neighbor_stack <= neighbor_alpha_limit, axis=0)

    not_core = alpha < protect_core_alpha

    mask = is_bright & candidate_alpha & touches_transparent_edge & not_core
    rgba[mask, 3] = 0

    soften_mask = (
        (~mask)
        & (alpha > 0)
        & (alpha <= 180)
        & touches_transparent_edge
        & (rgb.mean(axis=2) >= 210)
    )
    rgba[soften_mask, 0] = np.minimum(rgba[soften_mask, 0], 170)
    rgba[soften_mask, 1] = np.minimum(rgba[soften_mask, 1], 145)
    rgba[soften_mask, 2] = np.minimum(rgba[soften_mask, 2], 120)

    return Image.fromarray(rgba, mode="RGBA")


def process_folder(input_dir: Path, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for path in sorted(input_dir.iterdir()):
        if not path.is_file() or path.suffix.lower() not in SUPPORTED:
            continue
        img = Image.open(path).convert("RGBA")
        cleaned = cleanup_white_fringe(img)
        cleaned.save(output_dir / path.name)
        print(f"Processed: {path.name}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Remove white fringe/halo from transparent cigar cutouts.")
    parser.add_argument("--input", default="assets/cigars", help="Input folder")
    parser.add_argument("--output", default="assets/cigars_clean_edges", help="Output folder")
    args = parser.parse_args()

    input_dir = Path(args.input)
    output_dir = Path(args.output)

    if not input_dir.exists():
        raise SystemExit(f"Input folder not found: {input_dir}")

    process_folder(input_dir, output_dir)
    print(f"\\nDone. Cleaned files saved to: {output_dir}")


if __name__ == "__main__":
    main()
