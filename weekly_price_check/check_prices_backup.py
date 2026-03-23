#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import re
import sys
import time
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any, Iterable, Optional
from urllib.parse import urlparse

import requests
from bs4 import BeautifulSoup

USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/122.0.0.0 Safari/537.36"
)

HEADERS = {
    "User-Agent": USER_AGENT,
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-GB,en;q=0.9",
    "Cache-Control": "no-cache",
    "Pragma": "no-cache",
}

SUPPORTED_DOMAINS = {
    "www.cgarsltd.co.uk": "cgars",
    "cgarsltd.co.uk": "cgars",
    "www.havanahouse.co.uk": "havanahouse",
    "havanahouse.co.uk": "havanahouse",
    "www.simplycigars.co.uk": "simplycigars",
    "simplycigars.co.uk": "simplycigars",
    "egmcigars.com": "egm",
    "www.egmcigars.com": "egm",
    "cigarworld.co.uk": "cigarworld",
    "www.cigarworld.co.uk": "cigarworld",
}

GOOGLE_SHOPPING_PREFIX = "https://www.google.com/search?ibp=oshop"
MONEY_RE = re.compile(r"(?:£|&pound;)?\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)")
JSON_PRICE_RE = re.compile(r'"price"\s*:\s*"?([0-9]+(?:\.[0-9]{1,2})?)"?')


@dataclass
class CheckResult:
    cigar_name: str
    source_group: str
    retailer: str
    url: str
    domain: str
    status: str
    field: str
    previous_value: str
    current_value: str
    note: str


def now_stamp() -> str:
    return dt.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")


def money_to_float(value: str | None) -> Optional[float]:
    if not value:
        return None
    text = str(value).strip().replace(",", "").replace("£", "")
    try:
        return round(float(text), 2)
    except ValueError:
        return None


def normalise_money(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, (int, float)):
        return f"£{float(value):.2f}"
    text = str(value).strip()
    if not text:
        return ""
    num = money_to_float(text)
    if num is None:
        return text
    return f"£{num:.2f}"


def same_money(a: str, b: str) -> bool:
    af = money_to_float(a)
    bf = money_to_float(b)
    if af is not None and bf is not None:
        return abs(af - bf) < 0.001
    return a.strip() == b.strip()


def get_domain(url: str) -> str:
    try:
        return urlparse(url).netloc.lower()
    except Exception:
        return ""


def supported_retailer_key(url: str) -> Optional[str]:
    return SUPPORTED_DOMAINS.get(get_domain(url))


def is_google_shopping_url(url: str) -> bool:
    return url.startswith(GOOGLE_SHOPPING_PREFIX)


def ensure_dirs(base_dir: Path) -> tuple[Path, Path]:
    base_dir.mkdir(parents=True, exist_ok=True)
    snapshots = base_dir / "snapshots"
    reports = base_dir / "reports"
    snapshots.mkdir(parents=True, exist_ok=True)
    reports.mkdir(parents=True, exist_ok=True)
    return snapshots, reports


def fetch_html(url: str, timeout: int) -> str:
    response = requests.get(url, headers=HEADERS, timeout=timeout)
    response.raise_for_status()
    return response.text


def first_text(soup: BeautifulSoup, selectors: Iterable[str]) -> str:
    for sel in selectors:
        node = soup.select_one(sel)
        if node:
            text = node.get_text(" ", strip=True)
            if text:
                return text
    return ""


def extract_money_from_text(text: str) -> Optional[str]:
    if not text:
        return None

    matches = MONEY_RE.findall(text)
    if not matches:
        return None

    cleaned: list[float] = []

    for m in matches:
        try:
            val = float(m.replace(",", ""))
            if 2 <= val <= 150:
                cleaned.append(val)
        except Exception:
            continue

    if not cleaned:
        return None

    return normalise_money(min(cleaned))


def extract_jsonld_price(html: str) -> Optional[str]:
    matches = JSON_PRICE_RE.findall(html)
    cleaned: list[float] = []

    for m in matches:
        try:
            val = float(m)
            if 2 <= val <= 150:
                cleaned.append(val)
        except Exception:
            continue

    if not cleaned:
        return None

    return normalise_money(min(cleaned))


def infer_stock(text_blob: str) -> str:
    low = text_blob.lower()
    if "out of stock" in low or "sold out" in low or "unavailable" in low:
        return "Out of Stock"
    if "in stock" in low or "available" in low:
        return "In Stock"
    return ""


def parse_generic(html: str) -> dict[str, str]:
    soup = BeautifulSoup(html, "html.parser")
    blob = soup.get_text(" ", strip=True)
    price = (
        extract_money_from_text(first_text(soup, [
            "[itemprop='price']",
            ".price",
            ".product-price",
            ".special-price",
            ".our-price",
            ".current-price",
        ]))
        or extract_jsonld_price(html)
        or extract_money_from_text(blob)
        or ""
    )
    stock = infer_stock(blob)
    return {"price": price, "stock": stock}


def parse_cgars(html: str) -> dict[str, str]:
    soup = BeautifulSoup(html, "html.parser")
    blob = soup.get_text(" ", strip=True)
    price_text = first_text(soup, [
        "span[itemprop='price']",
        ".productSpecialPrice",
        ".productPrice",
        "#product-price-current",
        ".price",
    ])
    price = extract_money_from_text(price_text) or extract_jsonld_price(html) or ""
    stock = infer_stock(blob)
    return {"price": price, "stock": stock}


def parse_havanahouse(html: str) -> dict[str, str]:
    soup = BeautifulSoup(html, "html.parser")
    blob = soup.get_text(" ", strip=True)
    price_text = first_text(soup, [
        "p.price",
        ".price .woocommerce-Price-amount",
        ".summary .price",
        "[itemprop='price']",
    ])
    price = extract_money_from_text(price_text) or extract_jsonld_price(html) or ""
    stock = infer_stock(blob)
    return {"price": price, "stock": stock}


def parse_simplycigars(html: str) -> dict[str, str]:
    soup = BeautifulSoup(html, "html.parser")
    blob = soup.get_text(" ", strip=True)
    price_text = first_text(soup, [
        ".productSpecialPrice",
        ".normalprice",
        ".price",
        "[itemprop='price']",
    ])
    price = extract_money_from_text(price_text) or extract_jsonld_price(html) or ""
    stock = infer_stock(blob)
    return {"price": price, "stock": stock}


def parse_egm(html: str) -> dict[str, str]:
    soup = BeautifulSoup(html, "html.parser")
    blob = soup.get_text(" ", strip=True)
    price_text = first_text(soup, [
        "[data-product-price]",
        ".price",
        ".product__price",
        ".price-item",
        "[itemprop='price']",
    ])
    price = extract_money_from_text(price_text) or extract_jsonld_price(html) or ""
    stock = infer_stock(blob)
    return {"price": price, "stock": stock}


def parse_cigarworld(html: str) -> dict[str, str]:
    soup = BeautifulSoup(html, "html.parser")
    price = extract_jsonld_price(html)
    if not price:
        blob = soup.get_text(" ", strip=True)
        price = extract_money_from_text(blob)
    stock = infer_stock(soup.get_text(" ", strip=True))
    return {"price": price or "", "stock": stock}


PARSERS = {
    "cgars": parse_cgars,
    "havanahouse": parse_havanahouse,
    "simplycigars": parse_simplycigars,
    "egm": parse_egm,
    "cigarworld": parse_cigarworld,
}


def scrape_price(url: str, timeout: int) -> tuple[Optional[dict[str, str]], str]:
    if not url:
        return None, "empty URL"
    if is_google_shopping_url(url):
        return None, "Google shopping URL skipped"
    key = supported_retailer_key(url)
    if not key:
        return None, f"Unsupported domain: {get_domain(url) or 'unknown'}"
    html = fetch_html(url, timeout=timeout)
    parser = PARSERS.get(key, parse_generic)
    return parser(html), ""


def snapshot_row(cigar_name: str, source_group: str, retailer: str, url: str, price: str, stock: str) -> dict[str, str]:
    return {
        "cigar_name": cigar_name,
        "source_group": source_group,
        "retailer": retailer,
        "url": url,
        "price": normalise_money(price),
        "stock": stock or "",
    }


def iterate_price_entries(data: list[dict[str, Any]]):
    for cigar in data:
        cigar_name = cigar.get("name", "Unknown cigar")
        for source_group in ("ukPrices", "euPrices"):
            for entry in cigar.get(source_group, []):
                yield cigar, cigar_name, source_group, entry


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "cigar_name",
        "source_group",
        "retailer",
        "url",
        "domain",
        "status",
        "field",
        "previous_value",
        "current_value",
        "note",
    ]
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def build_results(data: list[dict[str, Any]], timeout: int, pause: float) -> tuple[list[CheckResult], list[dict[str, str]]]:
    results: list[CheckResult] = []
    snapshot: list[dict[str, str]] = []

    for cigar, cigar_name, source_group, entry in iterate_price_entries(data):
        retailer = str(entry.get("retailer", "")).strip()
        url = str(entry.get("url", "")).strip()
        previous_price = normalise_money(entry.get("price", ""))
        domain = get_domain(url)

        if not url:
            results.append(CheckResult(
                cigar_name=cigar_name,
                source_group=source_group,
                retailer=retailer,
                url=url,
                domain=domain,
                status="skipped",
                field="price",
                previous_value=previous_price,
                current_value="",
                note="No URL",
            ))
            continue

        try:
            scraped, note = scrape_price(url, timeout)
            if scraped is None:
                results.append(CheckResult(
                    cigar_name=cigar_name,
                    source_group=source_group,
                    retailer=retailer,
                    url=url,
                    domain=domain,
                    status="unsupported" if "Unsupported domain" in note else "skipped",
                    field="price",
                    previous_value=previous_price,
                    current_value="",
                    note=note,
                ))
                continue

            current_price = normalise_money(scraped.get("price", ""))
            current_stock = scraped.get("stock", "")
            snapshot.append(snapshot_row(cigar_name, source_group, retailer, url, current_price, current_stock))

            if not current_price:
                results.append(CheckResult(
                    cigar_name=cigar_name,
                    source_group=source_group,
                    retailer=retailer,
                    url=url,
                    domain=domain,
                    status="error",
                    field="price",
                    previous_value=previous_price,
                    current_value="",
                    note="Price not extracted",
                ))
                continue

            prev = money_to_float(previous_price)
            curr = money_to_float(current_price)

            if prev is not None and curr is not None:
                if curr > 150:
                    results.append(CheckResult(
                        cigar_name=cigar_name,
                        source_group=source_group,
                        retailer=retailer,
                        url=url,
                        domain=domain,
                        status="error",
                        field="price",
                        previous_value=previous_price,
                        current_value=current_price,
                        note="Rejected: suspiciously high price",
                    ))
                    continue

                if curr > prev * 3:
                    results.append(CheckResult(
                        cigar_name=cigar_name,
                        source_group=source_group,
                        retailer=retailer,
                        url=url,
                        domain=domain,
                        status="error",
                        field="price",
                        previous_value=previous_price,
                        current_value=current_price,
                        note="Rejected: unrealistic jump",
                    ))
                    continue

            if same_money(previous_price, current_price):
                results.append(CheckResult(
                    cigar_name=cigar_name,
                    source_group=source_group,
                    retailer=retailer,
                    url=url,
                    domain=domain,
                    status="unchanged",
                    field="price",
                    previous_value=previous_price,
                    current_value=current_price,
                    note=current_stock or "",
                ))
            else:
                results.append(CheckResult(
                    cigar_name=cigar_name,
                    source_group=source_group,
                    retailer=retailer,
                    url=url,
                    domain=domain,
                    status="changed",
                    field="price",
                    previous_value=previous_price,
                    current_value=current_price,
                    note=current_stock or "",
                ))

        except requests.HTTPError as exc:
            status_code = getattr(exc.response, "status_code", "?")
            results.append(CheckResult(
                cigar_name=cigar_name,
                source_group=source_group,
                retailer=retailer,
                url=url,
                domain=domain,
                status="error",
                field="price",
                previous_value=previous_price,
                current_value="",
                note=f"HTTP {status_code}",
            ))
        except requests.RequestException as exc:
            results.append(CheckResult(
                cigar_name=cigar_name,
                source_group=source_group,
                retailer=retailer,
                url=url,
                domain=domain,
                status="error",
                field="price",
                previous_value=previous_price,
                current_value="",
                note=f"Request failed: {exc.__class__.__name__}",
            ))
        except Exception as exc:
            results.append(CheckResult(
                cigar_name=cigar_name,
                source_group=source_group,
                retailer=retailer,
                url=url,
                domain=domain,
                status="error",
                field="price",
                previous_value=previous_price,
                current_value="",
                note=f"Parser error: {exc.__class__.__name__}",
            ))

        if pause > 0:
            time.sleep(pause)

    return results, snapshot


def print_summary(results: list[CheckResult], snapshot_count: int, reports_dir: Path, stamp: str) -> None:
    changed = [r for r in results if r.status == "changed"]
    unchanged = [r for r in results if r.status == "unchanged"]
    skipped = [r for r in results if r.status == "skipped"]
    unsupported = [r for r in results if r.status == "unsupported"]
    errors = [r for r in results if r.status == "error"]

    print("\n=== Cigar Ledger weekly price check ===")
    print(f"Timestamp: {stamp}")
    print(f"Changed: {len(changed)}")
    print(f"Unchanged: {len(unchanged)}")
    print(f"Skipped: {len(skipped)}")
    print(f"Unsupported: {len(unsupported)}")
    print(f"Errors: {len(errors)}")
    print(f"Snapshot rows written: {snapshot_count}")
    print(f"CSV report: {reports_dir / f'price_changes_{stamp}.csv'}")

    if changed:
        print("\n--- Weekly changes vs current prices.json ---")
        for r in changed[:50]:
            print(f"- {r.cigar_name} | {r.retailer} | {r.previous_value} -> {r.current_value}")
        if len(changed) > 50:
            print(f"... and {len(changed) - 50} more")

    if errors:
        print("\n--- Errors ---")
        for r in errors[:20]:
            print(f"- {r.cigar_name} | {r.retailer} | {r.note}")
        if len(errors) > 20:
            print(f"... and {len(errors) - 20} more")

    if skipped or unsupported:
        print("\n--- Skipped / unsupported ---")
        preview = (skipped + unsupported)[:20]
        for r in preview:
            print(f"- {r.cigar_name} | {r.retailer} | {r.note}")
        total = len(skipped) + len(unsupported)
        if total > 20:
            print(f"... and {total - 20} more")


def main() -> int:
    parser = argparse.ArgumentParser(description="Cigar Ledger weekly price checker")
    parser.add_argument("--input", required=True, help="Path to current prices.json")
    parser.add_argument("--output-dir", default="price_check_output", help="Where snapshots/reports will be written")
    parser.add_argument("--timeout", type=int, default=20, help="HTTP timeout in seconds")
    parser.add_argument("--pause", type=float, default=0.5, help="Pause between requests in seconds")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    snapshots_dir, reports_dir = ensure_dirs(output_dir)

    if not input_path.exists():
        print(f"Input file not found: {input_path}", file=sys.stderr)
        return 1

    data = json.loads(input_path.read_text(encoding="utf-8"))
    stamp = now_stamp()

    results, snapshot_rows = build_results(data, timeout=args.timeout, pause=args.pause)

    report_path = reports_dir / f"price_changes_{stamp}.csv"
    snapshot_path = snapshots_dir / f"snapshot_{stamp}.json"
    raw_results_path = reports_dir / f"raw_results_{stamp}.json"

    write_csv(report_path, [asdict(r) for r in results])
    write_json(snapshot_path, snapshot_rows)
    write_json(raw_results_path, [asdict(r) for r in results])

    print_summary(results, len(snapshot_rows), reports_dir, stamp)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())