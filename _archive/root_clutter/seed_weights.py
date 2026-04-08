#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

INPUT = Path('assets/data/prices.json')
OUTPUT = Path('assets/data/prices.json')
WEIGHT_FACTOR = 0.064

VERIFIED_WEIGHTS = {
    'Plasencia Alma Fuerte Sixto II': (22.7, 'verified: Neptune Cigar'),
    'Davidoff Winston Churchill The Late Hour Toro': (20.9, 'verified: Neptune Cigar'),
}


def estimate_weight(length_mm: int, ring_gauge: int) -> float:
    length_inches = length_mm / 25.4
    return round(length_inches * ring_gauge * WEIGHT_FACTOR, 1)


def main() -> None:
    data = json.loads(INPUT.read_text())

    for cigar in data:
        name = cigar.get('name', '')
        if name in VERIFIED_WEIGHTS:
            weight, source = VERIFIED_WEIGHTS[name]
            cigar['weightGrams'] = weight
            cigar['weightSource'] = source
            continue

        existing = cigar.get('weightGrams')
        try:
            existing = float(existing)
        except (TypeError, ValueError):
            existing = None

        if existing and existing > 0:
            cigar['weightGrams'] = round(existing, 1)
            cigar['weightSource'] = cigar.get('weightSource') or 'manual'
        else:
            cigar['weightGrams'] = estimate_weight(
                int(cigar.get('lengthMm', 0)),
                int(cigar.get('ringGauge', 0)),
            )
            cigar['weightSource'] = 'estimated: size formula'

    OUTPUT.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '
')
    print(f'Updated {len(data)} cigars in {OUTPUT}')


if __name__ == '__main__':
    main()
