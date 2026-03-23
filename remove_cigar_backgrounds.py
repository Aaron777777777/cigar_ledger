#!/usr/bin/env python3
from __future__ import annotations

from collections import deque
from pathlib import Path
from PIL import Image
import shutil

PROJECT_ROOT = Path.cwd()
INPUT_DIR = PROJECT_ROOT / "assets" / "cigars"
BACKUP_DIR = PROJECT_ROOT / "assets" / "cigars_backup_before_bg_remove_v2"

# Stronger settings
WHITE_MIN = 235        # edge pixel must be very bright
MAX_CHANNEL_DELTA = 20 # must be close to grey/white
SOFT_MIN = 220         # softly fade nearby bright border pixels too


def is_near_white(r: int, g: int, b: int, a: int) -> bool:
    if a == 0:
        return False
    if min(r, g, b) < WHITE_MIN:
        return False
    if max(r, g, b) - min(r, g, b) > MAX_CHANNEL_DELTA:
        return False
    return True


def is_soft_white(r: int, g: int, b: int, a: int) -> bool:
    if a == 0:
        return False
    if min(r, g, b) < SOFT_MIN:
        return False
    if max(r, g, b) - min(r, g, b) > 30:
        return False
    return True


def process_png(path: Path) -> bool:
    img = Image.open(path).convert("RGBA")
    px = img.load()
    w, h = img.size

    visited = [[False] * h for _ in range(w)]
    to_clear = set()
    q = deque()

    # Seed from all border pixels that are white/near-white
    for x in range(w):
        for y in (0, h - 1):
            r, g, b, a = px[x, y]
            if is_near_white(r, g, b, a):
                q.append((x, y))
                visited[x][y] = True
                to_clear.add((x, y))
    for y in range(h):
        for x in (0, w - 1):
            r, g, b, a = px[x, y]
            if not visited[x][y] and is_near_white(r, g, b, a):
                q.append((x, y))
                visited[x][y] = True
                to_clear.add((x, y))

    # Flood-fill only border-connected white background
    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[nx][ny]:
                visited[nx][ny] = True
                r, g, b, a = px[nx, ny]
                if is_near_white(r, g, b, a):
                    q.append((nx, ny))
                    to_clear.add((nx, ny))

    changed = False

    # Hard-clear the border-connected white background
    for x, y in to_clear:
        r, g, b, a = px[x, y]
        if a != 0:
            px[x, y] = (r, g, b, 0)
            changed = True

    # Soft-clean any pixels touching removed area so edges look less boxy
    neighbors = list(to_clear)
    for x, y in neighbors:
        for nx in range(max(0, x - 1), min(w, x + 2)):
            for ny in range(max(0, y - 1), min(h, y + 2)):
                r, g, b, a = px[nx, ny]
                if a == 0:
                    continue
                if is_soft_white(r, g, b, a):
                    brightness = (r + g + b) / 3
                    # brighter = more transparent
                    alpha_scale = max(0.0, min(1.0, (255 - brightness) / (255 - SOFT_MIN)))
                    new_a = int(a * alpha_scale)
                    if new_a < a:
                        px[nx, ny] = (r, g, b, new_a)
                        changed = True

    if changed:
        img.save(path)

    return changed


def main() -> None:
    if not INPUT_DIR.exists():
        raise SystemExit(f"Folder not found: {INPUT_DIR}")

    pngs = sorted(INPUT_DIR.glob("*.png"))
    if not pngs:
        raise SystemExit(f"No PNG files found in: {INPUT_DIR}")

    BACKUP_DIR.mkdir(parents=True, exist_ok=True)

    changed_count = 0
    for png in pngs:
        backup = BACKUP_DIR / png.name
        if not backup.exists():
            shutil.copy2(png, backup)

        changed = process_png(png)
        if changed:
            changed_count += 1
            print(f"Updated: {png.name}")
        else:
            print(f"No change: {png.name}")

    print(f"\nDone. {changed_count} image(s) updated.")
    print(f"Backup folder: {BACKUP_DIR}")


if __name__ == "__main__":
    main()
