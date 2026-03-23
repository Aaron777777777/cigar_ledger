import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const pricesFilePath = 'assets/data/prices.json';
const retailerLinksFilePath = 'assets/data/retailer_links.json';

Future<void> main() async {
  final pricesFile = File(pricesFilePath);
  final linksFile = File(retailerLinksFilePath);

  final cigars = jsonDecode(await pricesFile.readAsString());
  final links = jsonDecode(await linksFile.readAsString());

  for (final cigar in cigars) {
    final name = cigar['name'];

    if (!links.containsKey(name)) {
      print("Skipping: $name (no retailer links)");
      continue;
    }

    final cigarLinks = links[name];

    print("\nChecking: $name");

    final ukPrices = <Map<String, dynamic>>[];
    final euPrices = <Map<String, dynamic>>[];

    final boxQuantity = (cigar['boxQuantity'] ?? 1) as int;

    for (final entry in cigarLinks.entries) {
      final retailer = entry.key;
      final url = entry.value;

      // REMOVE SMOKE KING
      if (retailer == 'smokeking') continue;

      if (url == null || url.toString().isEmpty) continue;

      print("  Fetching $retailer");

      try {
        final response = await http.get(Uri.parse(url));
        final html = response.body;

        final price = extractPrice(retailer, html);

        if (price == null) {
          print("  Price not found");
          continue;
        }

        if (isEuRetailer(retailer)) {
          final perCigarPrice = price / boxQuantity;

          print(
            "  Found EU box price: £${price.toStringAsFixed(2)} "
            "-> per cigar: £${perCigarPrice.toStringAsFixed(2)}",
          );

          euPrices.add({
            "retailer": retailer,
            "boxPrice": price,
            "price": perCigarPrice,
            "url": url,
          });
        } else {
          print("  Found price: £${price.toStringAsFixed(2)}");

          ukPrices.add({
            "retailer": retailer,
            "price": price,
            "url": url,
          });
        }
      } catch (e) {
        print("  Error fetching page");
      }
    }

    if (ukPrices.isNotEmpty) {
      final prices = ukPrices.map((p) => p['price'] as double).toList();
      final avg = prices.reduce((a, b) => a + b) / prices.length;

      ukPrices.sort(
        (a, b) => ((a['price'] as double) - avg)
            .abs()
            .compareTo(((b['price'] as double) - avg).abs()),
      );

      final cheapest = ukPrices.first;

      cigar['ukPrices'] = [
        {
          "retailer": cheapest['retailer'],
          "price": "£${(cheapest['price'] as double).toStringAsFixed(2)}",
          "previousPrice":
              "£${(cheapest['price'] as double).toStringAsFixed(2)}",
          "stock": "In Stock",
          "url": cheapest['url'],
        }
      ];

      print(
        "  Saved cheapest UK: ${cheapest['retailer']} | "
        "£${(cheapest['price'] as double).toStringAsFixed(2)}",
      );
    }

    if (euPrices.isNotEmpty) {
      euPrices.sort(
        (a, b) => (a['price'] as double).compareTo(b['price'] as double),
      );

      final cheapest = euPrices.first;

      final euPerCigar = cheapest['price'] as double;
      final euBoxPrice = cheapest['boxPrice'] as double;

      double ukPriceValue = 0.0;
      if (cigar['ukPrices'] != null &&
          cigar['ukPrices'] is List &&
          (cigar['ukPrices'] as List).isNotEmpty) {
        final ukPriceString = cigar['ukPrices'][0]['price']
            .toString()
            .replaceAll('£', '')
            .trim();
        ukPriceValue = double.tryParse(ukPriceString) ?? 0.0;
      }

      final savingsPerCigar =
          ukPriceValue > 0 ? (ukPriceValue - euPerCigar) : 0.0;

      cigar['euPrices'] = [
        {
          "retailer": cheapest['retailer'],
          "boxPrice": "£${euBoxPrice.toStringAsFixed(2)}",
          "cigarPrice": "£${euPerCigar.toStringAsFixed(2)}",
          "dutyVat": "£0.00",
          "landedCost": "£${euPerCigar.toStringAsFixed(2)}",
          "savings": "£${savingsPerCigar.toStringAsFixed(2)}",
          "url": cheapest['url'],
        }
      ];

      print(
        "  Saved cheapest EU: ${cheapest['retailer']} | "
        "£${euPerCigar.toStringAsFixed(2)} per cigar",
      );
    }
  }

  await pricesFile.writeAsString(
    JsonEncoder.withIndent('  ').convert(cigars),
  );

  print("\nDone updating prices.");
}

double? extractPrice(String retailer, String html) {
  final priceRegex = RegExp(
    r'[€£]\s?(\d+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  final matches = priceRegex
      .allMatches(html)
      .map((m) => double.tryParse(m.group(1)!))
      .whereType<double>()
      .toList();

  if (matches.isEmpty) return null;

  List<double> filtered;

  if (isEuRetailer(retailer)) {
    filtered = matches.where((p) => p > 50 && p < 2000).toList();
  } else {
    filtered = matches.where((p) => p > 20 && p < 80).toList();
  }

  if (filtered.isEmpty) return null;

  filtered.sort();

  if (!isEuRetailer(retailer)) {
    return filtered[filtered.length ~/ 2];
  }

  return filtered.last;
}

bool isEuRetailer(String r) {
  return r == 'egm' || r == 'swisscubancigars' || r == 'topcubans';
}