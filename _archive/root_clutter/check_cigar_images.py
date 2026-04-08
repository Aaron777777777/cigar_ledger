from pathlib import Path
import re

print("\nChecking cigar image usage...\n")

project_root = Path.cwd()
assets_dir = project_root / "assets" / "cigars"
lib_dir = project_root / "lib"

# Collect actual images
actual_images = {p.name for p in assets_dir.glob("*.png")}

# Find referenced images
pattern = re.compile(r'assets/cigars/([a-z0-9_]+\.png)')

referenced_images = set()

for file in lib_dir.rglob("*.dart"):
    try:
        text = file.read_text()
        matches = pattern.findall(text)
        referenced_images.update(matches)
    except:
        pass

# Compare
unused_images = sorted(actual_images - referenced_images)
missing_images = sorted(referenced_images - actual_images)

print("Total image files:", len(actual_images))
print("Images used in app:", len(referenced_images))

print("\nIMAGES NOT USED IN APP:")
for img in unused_images:
    print(img)

print("\nIMAGES REFERENCED BUT MISSING:")
for img in missing_images:
    print(img)