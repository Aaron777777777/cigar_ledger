#!/bin/bash
set -e

cd ~/Projects/cigar_ledger

mkdir -p assets/cigars_inbox
mkdir -p assets/cigars_raw
mkdir -p /tmp/cigar_weekly_polished

HAS_FILES=$(find assets/cigars_inbox -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.webp" -o -iname "*.jpg" -o -iname "*.jpeg" \) | head -n 1)

if [ -z "$HAS_FILES" ]; then
  echo "No new cigar images found in assets/cigars_inbox"
  exit 0
fi

rm -rf /tmp/cigar_weekly_polished
mkdir -p /tmp/cigar_weekly_polished

rsync -a assets/cigars_inbox/ assets/cigars_raw/
python3 polish_cigar_images.py --input assets/cigars_inbox --output /tmp/cigar_weekly_polished
rsync -a /tmp/cigar_weekly_polished/ assets/cigars/

find assets/cigars_inbox -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.webp" -o -iname "*.jpg" -o -iname "*.jpeg" \) -delete

echo "Done. Only new inbox cigars were polished and copied into assets/cigars."
