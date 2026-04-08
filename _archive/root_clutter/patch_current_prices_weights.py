#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
from pathlib import Path

PROJECT_ROOT = Path.cwd()
PRICES_FILE = PROJECT_ROOT / "assets" / "data" / "prices.json"
OUTPUT_JSON = PROJECT_ROOT / "assets" / "data" / "prices_weighted_fixed.json"
OUTPUT_CSV = PROJECT_ROOT / "current_catalog_weight_review.csv"

FACTOR = 0.064  # improved estimate factor

def estimate_weight_grams(ring_gauge: int, length_mm: int) -> float:
    if not ring_gauge or not length_mm:
        return 0.0
    length_inches = length_mm / 25.4
    return round(length_inches * ring_gauge * FACTOR, 1)

def main() -> None:
    if not PRICES_FILE.exists():
        raise SystemExit(f"Could not find {PRICES_FILE}")

    with PRICES_FILE.open("r", encoding="utf-8") as f:
        cigars = json.load(f)

    review_rows = []
    updated = 0
    preserved = 0
    still_missing = 0

    for cigar in cigars:
        name = cigar.get("name", "")
        ring_gauge = int(cigar.get("ringGauge", 0) or 0)
        length_mm = int(cigar.get("lengthMm", 0) or 0)
        current_weight = float(cigar.get("weightGrams", 0) or 0)

        if current_weight > 0:
            preserved += 1
            status = "kept existing weight"
            suggested = current_weight
        else:
            suggested = estimate_weight_grams(ring_gauge, length_mm)
            if suggested > 0:
                cigar["weightGrams"] = suggested
                cigar["weightSource"] = "estimated: size formula (0.064)"
                updated += 1
                status = "added estimated weight"
            else:
                cigar["weightGrams"] = 0.0
                cigar["weightSource"] = "missing size data - manual review"
                still_missing += 1
                status = "still needs manual review"

        review_rows.append({
            "name": name,
            "ringGauge": ring_gauge,
            "lengthMm": length_mm,
            "weightGrams": cigar.get("weightGrams", 0),
            "weightSource": cigar.get("weightSource", ""),
            "status": status,
        })

    with OUTPUT_JSON.open("w", encoding="utf-8") as f:
        json.dump(cigars, f, indent=2, ensure_ascii=False)

    with OUTPUT_CSV.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["name", "ringGauge", "lengthMm", "weightGrams", "weightSource", "status"],
        )
        writer.writeheader()
        writer.writerows(review_rows)

    print(f"Done.")
    print(f"Preserved existing weights: {preserved}")
    print(f"Added estimated weights:   {updated}")
    print(f"Still need manual review:  {still_missing}")
    print(f"Wrote: {OUTPUT_JSON}")
    print(f"Wrote: {OUTPUT_CSV}")

if __name__ == "__main__":
    main()
