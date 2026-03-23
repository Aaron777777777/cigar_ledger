import json
import os
import re
import csv
from urllib.parse import quote_plus

PRICES_JSON = "assets/data/prices.json"
CHECKPOINT_CSV = "assisted_updater_progress.csv"

UK_RETAILERS = [
    "cgars",
    "havanahouse",
    "simplycigars",
]

EU_RETAILERS = [
    "egm",
    "cigarworld",
]

ALL_RETAILERS = UK_RETAILERS + EU_RETAILERS

SEARCH_PATTERNS = {
    "cgars": "https://www.cgarsltd.co.uk/index.php?search={query}",
    "havanahouse": "https://www.havanahouse.co.uk/catalogsearch/result/?q={query}",
    "simplycigars": "https://www.simplycigars.co.uk/search?type=product&q={query}",
    "egm": "https://egmcigars.com/search?q={query}",
    "cigarworld": "https://www.cigarworld.de/suche?search={query}",
}

PRICE_RE = re.compile(r"\d+(?:\.\d{1,2})?")


def load_prices():
    with open(PRICES_JSON, "r", encoding="utf-8") as f:
        return json.load(f)


def save_prices(data):
    with open(PRICES_JSON, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def normalise_query(name: str) -> str:
    return quote_plus(name.replace(".", " "))


def retailer_search_url(retailer: str, cigar_name: str) -> str:
    pattern = SEARCH_PATTERNS[retailer]
    return pattern.format(query=normalise_query(cigar_name))


def parse_price_input(raw: str) -> str:
    raw = raw.strip().replace("£", "")
    if not raw:
        return ""
    match = PRICE_RE.search(raw)
    if not match:
        return ""
    return match.group(0)


def ensure_structure(cigar: dict):
    cigar.setdefault("ukPrices", [])
    cigar.setdefault("euPrices", [])

    existing_uk = {entry.get("retailer") for entry in cigar["ukPrices"]}
    for retailer in UK_RETAILERS:
        if retailer not in existing_uk:
            cigar["ukPrices"].append(
                {
                    "retailer": retailer,
                    "price": "",
                    "previousPrice": "",
                    "stock": "",
                    "url": "",
                }
            )

    existing_eu = {entry.get("retailer") for entry in cigar["euPrices"]}
    for retailer in EU_RETAILERS:
        if retailer not in existing_eu:
            cigar["euPrices"].append(
                {
                    "retailer": retailer,
                    "price": "",
                    "cigarPrice": "",
                    "dutyVat": "",
                    "landedCost": "",
                    "savings": "",
                    "url": "",
                }
            )


def get_entry(cigar: dict, retailer: str) -> dict:
    bucket = cigar["euPrices"] if retailer in EU_RETAILERS else cigar["ukPrices"]
    for entry in bucket:
        if entry.get("retailer") == retailer:
            return entry
    raise ValueError(f"Retailer entry missing for {retailer}")


def append_checkpoint(row):
    file_exists = os.path.exists(CHECKPOINT_CSV)
    with open(CHECKPOINT_CSV, "a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(["cigar", "retailer", "price", "url"])
        writer.writerow(row)


def cigar_needs_processing(cigar: dict) -> bool:
    for entry in cigar.get("ukPrices", []):
        if not entry.get("price") or not entry.get("url"):
            return True

    for entry in cigar.get("euPrices", []):
        if not entry.get("price") or not entry.get("url"):
            return True

    return False


def process_cigar(cigar: dict):
    ensure_structure(cigar)
    cigar_name = cigar.get("name", "")
    box_qty = cigar.get("boxQuantity", "")

    print("\n" + "=" * 80)
    print(f"CIGAR: {cigar_name}")
    print(f"BOX QUANTITY: {box_qty}")
    print("=" * 80)

    for retailer in ALL_RETAILERS:
        entry = get_entry(cigar, retailer)

        existing_price = entry.get("price", "")
        existing_url = entry.get("url", "")

        if existing_price and existing_url:
            print(f"[SKIP] {retailer} already populated: {existing_price}")
            continue

        print(f"\nRETAILER: {retailer}")
        print(f"Search URL:\n{retailer_search_url(retailer, cigar_name)}")
        print("Open the search URL in your browser, find the correct product, then paste:")
        print("- product URL")
        if retailer in EU_RETAILERS:
            print("- BOX price shown on page (enter final GBP-converted value)")
        else:
            print("- SINGLE cigar price shown on page (GBP only)")

        product_url = input("Product URL (leave blank to skip): ").strip()
        if not product_url:
            print("Skipped.")
            continue

        price_input = input("Displayed price in GBP (numbers only or £xx.xx): ").strip()
        price = parse_price_input(price_input)
        if not price:
            print("Invalid price, skipped.")
            continue

        if retailer in EU_RETAILERS:
            entry["url"] = product_url
            entry["price"] = price
            entry["cigarPrice"] = f"£{price}"
            entry["dutyVat"] = "£0.00"
            entry["landedCost"] = f"£{price}"
            entry["savings"] = "£0.00"
        else:
            entry["url"] = product_url
            entry["price"] = f"£{price}"
            entry["previousPrice"] = f"£{price}"
            entry["stock"] = "In Stock"

        append_checkpoint([cigar_name, retailer, price, product_url])
        print(f"Saved {retailer}: £{price}")


def main():
    data = load_prices()

    print("Browser-assisted Cigar Ledger Updater")
    print("Newest cigars are processed first.")
    print("This is designed to be accurate, not magical.")
    print("You visually confirm the right product; the script stores the data cleanly.")
    print()

    target = input("How many incomplete cigars do you want to process this run? (default 20): ").strip()
    try:
        limit = int(target) if target else 20
    except ValueError:
        limit = 20

    count = 0
    for cigar in reversed(data):
        ensure_structure(cigar)

        if not cigar_needs_processing(cigar):
            continue

        if count >= limit:
            break

        process_cigar(cigar)
        count += 1
        save_prices(data)
        print(f"\nProgress saved after {count} incomplete cigars.")

    save_prices(data)
    print("\nDone. prices.json has been updated.")
    print(f"Checkpoint log: {CHECKPOINT_CSV}")


if __name__ == "__main__":
    main()
