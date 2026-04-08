
import json
import os
from collections import Counter

# Adjust if your project path differs
PRICES_FILE = "assets/data/prices.json"
IMAGE_DIR = "assets/cigars"

print("\nCigar Ledger Catalogue Check\n" + "-"*35)

if not os.path.exists(PRICES_FILE):
    print(f"ERROR: Could not find {PRICES_FILE}")
    exit()

with open(PRICES_FILE, "r", encoding="utf-8") as f:
    cigars = json.load(f)

print(f"\nTotal cigars in catalogue: {len(cigars)}")

# ---- Check duplicates ----
names = [c["name"] for c in cigars if "name" in c]
counts = Counter(names)
duplicates = [name for name, count in counts.items() if count > 1]

print("\nDuplicate cigars:")
if duplicates:
    for d in duplicates:
        print(" -", d)
else:
    print(" None")

# ---- Check images ----
missing_images = []
for c in cigars:
    img = c.get("imageUrl", "")
    if img:
        img_path = img.replace("assets/cigars/", "")
        full_path = os.path.join(IMAGE_DIR, img_path)
        if not os.path.exists(full_path):
            missing_images.append(img_path)

print("\nMissing images:")
if missing_images:
    for m in missing_images:
        print(" -", m)
else:
    print(" None")

# ---- Check prices ----
missing_prices = []
for c in cigars:
    uk = c.get("ukPrices", [])
    if not uk:
        missing_prices.append(c["name"])

print("\nCigars with NO UK price:")
if missing_prices:
    for m in missing_prices:
        print(" -", m)
else:
    print(" None")

print("\nCheck complete.\n")
