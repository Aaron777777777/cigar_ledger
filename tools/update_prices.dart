
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const String serpApiKey = String.fromEnvironment('SERPAPI_KEY');
const String pricesFilePath = 'assets/data/prices.json';

/// Strong UK cigar retailers to trust first.
/// Add to this over time as you validate more sources.
const List<String> preferredUkRetailers = [
  'cgars',
  'c.gars',
  'havana house',
  'montecristo cigars',
  'simply cigars',
  'cigar one',
  'davidoff of london',
  'j james',
  'jj fox',
  'turmeaus',
  'house of habanos',
  'the cigar club',
  'puro express',
  'havanas cigar merchants',
  'cigar importer',
];

/// Retailers / marketplaces / junk sources we do not trust for truth.
const List<String> blockedRetailerTerms = [
  'ebay',
  'etsy',
  'walmart',
  'amazon',
  'aliexpress',
  'facebook',
  'instagram',
  'tiktok',
  'pinterest',
  'liquor',
  'spirits',
  'wine',
  'gift',
  'market',
  'essentials',
  'club',
  'subscription',
  'auction',
  'reddit',
  'youtube',
];

/// Any of these means reject the result entirely.
/// No box conversion for now. Too risky.
const List<String> blockedTitleTerms = [
  'box',
  'box of',
  'pack',
  'pack of',
  'bundle',
  'sampler',
  'samplers',
  'humidor',
  'cabinet',
  'jar',
  'display',
  'collection',
  'assortment',
  '5-pack',
  '10-pack',
  '20-pack',
  '25-pack',
  '5 pack',
  '10 pack',
  '20 pack',
  '25 pack',
  '5ct',
  '10ct',
  '20ct',
  '25ct',
  '5 count',
  '10 count',
  '20 count',
  '25 count',
  'box pressed sampler',
];

/// Clear non-cigar / accessory / merch signals.
const List<String> unrelatedTerms = [
  'lighter',
  'ashtray',
  'cutter',
  'case',
  'torch',
  'shirt',
  'hat',
  'fragrance',
  'perfume',
  'drink',
  'whiskey',
  'whisky',
  'bourbon',
  'rum',
  'vodka',
  'tequila',
  'pipe',
  'cigarette',
  'vape',
  'accessory',
];

/// Debug safety mode.
/// Turn false only after you are happy with test runs.
const bool dryRun = false;

/// Safer initial test batch.
/// Expand only after checking output carefully.
const Set<String> testNames = {
  'Plasencia Sixto II Hexagon',
  'Plasencia Alma Fuerte Generacion V',
  'Cohiba Siglo II',
  'Montecristo No. 2',
  'Padron 1964 Anniversary Exclusivo Maduro',
};

Future<void> main() async {
  if (serpApiKey.isEmpty) {
    stderr.writeln(
      'Missing SERPAPI_KEY. Run with: dart run --define=SERPAPI_KEY=your_key tools/update_prices.dart',
    );
    exit(1);
  }

  final file = File(pricesFilePath);
  if (!await file.exists()) {
    stderr.writeln('Could not find $pricesFilePath');
    exit(1);
  }

  final raw = await file.readAsString();
  final List<dynamic> cigars = jsonDecode(raw) as List<dynamic>;

  int scanned = 0;
  int updated = 0;
  int skipped = 0;

  for (final item in cigars) {
    if (item is! Map<String, dynamic>) continue;

    final name = (item['name'] ?? '').toString().trim();
    final brand = (item['brand'] ?? '').toString().trim();

    if (name.isEmpty) {
      skipped++;
      continue;
    }

    // Keep the first run extremely controlled.
    if (!testNames.contains(name)) {
      continue;
    }

    scanned++;
    stdout.writeln('\nSearching: $name');

    final result = await _searchBestUkPrice(
      cigarName: name,
      brand: brand,
    );

    if (result == null) {
      stdout.writeln('  No confident UK single-cigar match found.');
      skipped++;
      continue;
    }

    final newUkPrices = [
      {
        'retailer': result.retailer,
        'price': _formatPrice(result.price),
        'previousPrice': _formatPrice(result.price),
        'stock': 'In Stock',
        'url': result.url,
      }
    ];

    if (dryRun) {
      stdout.writeln(
        '  DRY RUN ONLY -> Would save: ${result.retailer} | ${_formatPrice(result.price)}',
      );
    } else {
      item['ukPrices'] = newUkPrices;
      stdout.writeln(
        '  Saved: ${result.retailer} | ${_formatPrice(result.price)}',
      );
      updated++;
    }

    await Future.delayed(const Duration(milliseconds: 350));
  }

  if (!dryRun) {
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(cigars));
  }

  stdout.writeln('\nDone.');
  stdout.writeln('Scanned test cigars: $scanned');
  stdout.writeln('Updated: $updated');
  stdout.writeln('Skipped: $skipped');
  stdout.writeln('Mode: ${dryRun ? 'DRY RUN' : 'WRITE ENABLED'}');
}

Future<_PriceCandidate?> _searchBestUkPrice({
  required String cigarName,
  required String brand,
}) async {
 final query = cigarName.toLowerCase().contains('sixto ii')
    ? '"Plasencia Alma Fuerte Sixto II" cigar single uk'
    : '"$cigarName" cigar single uk';

  final uri = Uri.https('serpapi.com', '/search.json', {
    'engine': 'google',
    'q': query,
    'api_key': serpApiKey,
    'gl': 'uk',
    'hl': 'en',
    'num': '20',
  });

  final response = await http.get(uri);

  if (response.statusCode != 200) {
    stdout.writeln('  SerpAPI error: ${response.statusCode}');
    return null;
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final results = (data['organic_results'] as List?) ?? [];

  _PriceCandidate? best;
  double bestScore = -9999;

  for (final r in results) {
    if (r is! Map<String, dynamic>) continue;

    final title = (r['title'] ?? '').toString();
    final source = (r['source'] ?? '').toString();
    final link = (r['product_link'] ?? '').toString();
    final rawPriceString = '${r['title'] ?? ''} ${r['snippet'] ?? ''}';

    final rawPrice = _extractPrice(rawPriceString);
    if (rawPrice == null || rawPrice <= 0) continue;

    final score = _scoreCandidate(
      cigarName: cigarName,
      brand: brand,
      title: title,
      source: source,
      url: link,
      price: rawPrice,
    );

    if (!score.accepted) {
      stdout.writeln(
        '  Reject: $source | $rawPriceString | $title [${score.reason}]',
      );
      continue;
    }

    stdout.writeln(
      '  Candidate: $source | ${_formatPrice(rawPrice)} | '
      'score=${score.score.toStringAsFixed(1)} | $title',
    );

    if (score.score > bestScore) {
      bestScore = score.score;
      best = _PriceCandidate(
        retailer: source,
        price: rawPrice,
        url: link,
      );
    }
  }

  // Confidence floor. If it isn't clearly good, skip it.
  if (bestScore < 20) {
    return null;
  }

  return best;
}

_ScoreResult _scoreCandidate({
  required String cigarName,
  required String brand,
  required String title,
  required String source,
  required String url,
  required double price,
}) {
  final normTitle = _norm(title);
  final normSource = _norm(source);
  final normUrl = _norm(url);
  final normBrand = _norm(brand);

  if (normTitle.isEmpty && normSource.isEmpty) {
    return _ScoreResult.reject('empty result');
  }

  for (final bad in unrelatedTerms) {
    if (normTitle.contains(' $bad ') || normSource.contains(' $bad ')) {
      return _ScoreResult.reject('unrelated/accessory');
    }
  }

  for (final bad in blockedRetailerTerms) {
    if (normSource.contains(' $bad ') || normTitle.contains(' $bad ')) {
      return _ScoreResult.reject('blocked retailer/source');
    }
  }

  for (final bad in blockedTitleTerms) {
    if (normTitle.contains(' $bad ')) {
      return _ScoreResult.reject('box/bundle listing');
    }
  }

  // Single-cigar price sanity range.
  if (price < 5) {
    return _ScoreResult.reject('too cheap for premium cigar listing');
  }

  if (price > 80) {
    return _ScoreResult.reject('too expensive for single cigar');
  }

  final cigarTokens = _meaningfulTokens(cigarName);
  final titleTokens = _meaningfulTokens(title);

  int matchedTokens = 0;
  for (final token in cigarTokens) {
    if (titleTokens.contains(token)) {
      matchedTokens++;
    }
  }

  // Must match at least half the meaningful name tokens.
  final requiredMatches = (cigarTokens.length / 2).ceil();
  if (matchedTokens < requiredMatches) {
    return _ScoreResult.reject('weak name match');
  }

  double score = 0;

  if (normBrand.trim().isNotEmpty && normTitle.contains(normBrand.trim())) {
    score += 12;
  }

  score += matchedTokens * 6;

  bool preferredRetailer = false;
  for (final retailer in preferredUkRetailers) {
    if (normSource.contains(' $retailer ') || normUrl.contains(' $retailer ')) {
      preferredRetailer = true;
      break;
    }
  }

  if (preferredRetailer) {
    score += 20;
  } else {
    score -= 8;
  }

  if (url.contains('.co.uk') || url.contains('gl=uk')) {
    score += 5;
  }

  // Prefer clear single-stick language.
  if (normTitle.contains(' single ') ||
      normTitle.contains(' stick ') ||
      normTitle.contains(' cigar ')) {
    score += 4;
  }

  // Reward realistic premium single-stick bands.
  if (price >= 8 && price <= 40) {
    score += 10;
  } else if (price > 40 && price <= 60) {
    score += 4;
  }

  // Stronger penalty for vague titles.
  if (titleTokens.length < 2) {
    score -= 10;
  }

  return _ScoreResult.accept(score: score);
}

Set<String> _meaningfulTokens(String input) {
  const stopwords = {
    'the',
    'and',
    'a',
    'an',
    'cigar',
    'cigars',
    'single',
    'stick',
    'maduro',
    'natural',
    'tubo',
    'tubos',
  };

  return _norm(input)
      .split(' ')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .where((e) => !stopwords.contains(e))
      .toSet();
}

String _norm(String input) {
  final cleaned = input
      .toLowerCase()
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[^a-z0-9\.]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return ' $cleaned ';
}

double? _extractPrice(String input) {
  final match = RegExp(r'£\s?(\d+(?:\.\d{1,2})?)').firstMatch(input);
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}


String _formatPrice(double value) {
  return '£${value.toStringAsFixed(2)}';
}

class _PriceCandidate {
  final String retailer;
  final double price;
  final String url;

  _PriceCandidate({
    required this.retailer,
    required this.price,
    required this.url,
  });
}

class _ScoreResult {
  final bool accepted;
  final String reason;
  final double score;

  _ScoreResult._({
    required this.accepted,
    required this.reason,
    required this.score,
  });

  factory _ScoreResult.reject(String reason) {
    return _ScoreResult._(
      accepted: false,
      reason: reason,
      score: -999,
    );
  }

  factory _ScoreResult.accept({
    required double score,
  }) {
    return _ScoreResult._(
      accepted: true,
      reason: '',
      score: score,
    );
  }
}