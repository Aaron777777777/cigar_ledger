#!/usr/bin/env python3
from __future__ import annotations

import json
import csv
from pathlib import Path

PROJECT_ROOT = Path.cwd()
PRICES_FILE = PROJECT_ROOT / "assets" / "data" / "prices.json"
OUTPUT_CSV = PROJECT_ROOT / "weekly_price_check_report.csv"

def clean_price(value: str) -> str:
    if value is None:
        return ""
    return str(value).strip()

def check_supplier(cigar_name: str, brand: str, market: str, supplier: dict) -> dict:
    retailer = supplier.get("retailer", "").strip()
    price = clean_price(supplier.get("price", ""))
    url = supplier.get("url", "").strip()

    status_parts = []

    if not retailer:
        status_parts.append("missing retailer")
    if not price:
        status_parts.append("missing price")
    if not url:
        status_parts.append("missing url")

    if not status_parts:
        status = "ready to check"
    else:
        status = ", ".join(status_parts)

    return {
        "brand": brand,
        "cigar": cigar_name,
        "market": market,
        "retailer": retailer,
        "stored_price": price,
        "url": url,
        "status": status,
    }

def main() -> None:
    if not PRICES_FILE.exists():
        raise SystemExit(f"prices.json not found: {PRICES_FILE}")

    with PRICES_FILE.open("r", encoding="utf-8") as f:
        cigars = json.load(f)

    rows: list[dict] = []

    total_cigars = len(cigars)
    total_supplier_rows = 0
    ready_to_check = 0
    missing_price = 0
    missing_url = 0

    for cigar in cigars:
        cigar_name = cigar.get("name", "").strip()
        brand = cigar.get("brand", "").strip()

        for supplier in cigar.get("ukPrices", []):
            row = check_supplier(cigar_name, brand, "UK", supplier)
            rows.append(row)
            total_supplier_rows += 1

        for supplier in cigar.get("euPrices", []):
            row = check_supplier(cigar_name, brand, "EU", supplier)
            rows.append(row)
            total_supplier_rows += 1

    rows.sort(key=lambda r: (r["status"] != "ready to check", r["retailer"], r["brand"], r["cigar"]))

    for row in rows:
        if row["status"] == "ready to check":
            ready_to_check += 1
        if "missing price" in row["status"]:
            missing_price += 1
        if "missing url" in row["status"]:
            missing_url += 1

    with OUTPUT_CSV.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["brand", "cigar", "market", "retailer", "stored_price", "url", "status"],
        )
        writer.writeheader()
        writer.writerows(rows)

    print("\nCIGAR LEDGER – WEEKLY PRICE CHECK REPORT")
    print("-" * 44)
    print(f"Total cigars:            {total_cigars}")
    print(f"Supplier rows checked:   {total_supplier_rows}")
    print(f"Ready to check:          {ready_to_check}")
    print(f"Missing price:           {missing_price}")
    print(f"Missing url:             {missing_url}")
    print(f"\nCSV written to: {OUTPUT_CSV}")

    print("\nTop rows to check this week:")
    shown = 0
    for row in rows:
        if row["status"] == "ready to check":
            print(f"- [{row['retailer']}] {row['cigar']} ({row['stored_price']})")
            shown += 1
            if shown >= 20:
                break

    if shown == 0:
        print("- No fully ready rows found yet.")

if __name__ == "__main__":
    main()