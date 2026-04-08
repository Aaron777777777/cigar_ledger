import json

with open("cigar_list.txt") as f:
    cigars = [line.strip() for line in f if line.strip()]

output = []

for cigar in cigars:

    brand = cigar.split()[0]

    slug = cigar.lower()\
        .replace(" ", "_")\
        .replace(".", "")\
        .replace("'", "")\
        .replace("-", "_")

    entry = {
        "name": cigar,
        "brand": brand,
        "country": "Unknown",
        "ringGauge": 0,
        "lengthMm": 0,
        "strength": "Medium",
        "imageUrl": f"assets/cigars/{slug}.png",
        "boxQuantity": 25,
        "ukPrices": [
            {
                "retailer": "C.Gars Ltd",
                "price": "£0.00",
                "previousPrice": "£0.00",
                "stock": "In Stock",
                "url": "https://www.cgarsltd.co.uk/"
            }
        ],
        "euPrices": [
            {
                "retailer": "Montefortuna",
                "cigarPrice": "£0.00",
                "dutyVat": "£0.00",
                "landedCost": "£0.00",
                "savings": "£0.00",
                "url": "https://www.montefortunacigars.com/"
            }
        ]
    }

    output.append(entry)

print(json.dumps(output, indent=2))