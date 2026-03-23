import '../core/import_calculator.dart';

class Cigar {
  final String name;
  final String brand;
  final String country;
  final int ringGauge;
  final int lengthMm;
  final String strength;
  final String imageUrl;
  final int boxQuantity;
  final double? weightGrams;
  final String? weightSource;
  final List<double> priceHistory;
  final List<RetailerPrice> ukPrices;
  final List<ImportOption> euPrices;

  const Cigar({
    required this.name,
    required this.brand,
    required this.country,
    required this.ringGauge,
    required this.lengthMm,
    required this.strength,
    required this.imageUrl,
    this.boxQuantity = 25,
    this.weightGrams,
    this.weightSource,
    this.priceHistory = const [],
    required this.ukPrices,
    required this.euPrices,
  });

  bool get hasWeightOverride => weightGrams != null && weightGrams! > 0;

  bool get isEstimatedWeight {
    final source = (weightSource ?? '').toLowerCase();
    return source.contains('estimated');
  }

  double get importWeightGrams {
    if (hasWeightOverride) {
      return weightGrams!;
    }

    return ImportCalculator.estimateWeightFromSize(
      ringGauge: ringGauge,
      lengthMm: lengthMm,
    );
  }

  double get importBoxWeightGrams => importWeightGrams * boxQuantity;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'country': country,
      'ringGauge': ringGauge,
      'lengthMm': lengthMm,
      'strength': strength,
      'imageUrl': imageUrl,
      'boxQuantity': boxQuantity,
      'weightGrams': weightGrams,
      'weightSource': weightSource,
      'priceHistory': priceHistory,
      'ukPrices': ukPrices.map((price) => price.toMap()).toList(),
      'euPrices': euPrices.map((price) => price.toMap()).toList(),
    };
  }

  factory Cigar.fromMap(Map<String, dynamic> map) {
    final rawWeight = map['weightGrams'] ?? map['gramsPerCigar'];
    final rawWeightSource = map['weightSource'];

    return Cigar(
      name: (map['name'] ?? '').toString(),
      brand: (map['brand'] ?? '').toString(),
      country: (map['country'] ?? '').toString(),
      ringGauge: _toInt(map['ringGauge']),
      lengthMm: _toInt(map['lengthMm']),
      strength: (map['strength'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      boxQuantity: _toInt(map['boxQuantity'], fallback: 25),
      weightGrams: rawWeight == null ? null : _toDouble(rawWeight),
      weightSource: rawWeightSource == null ? null : rawWeightSource.toString(),
      priceHistory: (map['priceHistory'] as List?)
              ?.map((e) => _toDouble(e) ?? 0)
              .where((e) => e > 0)
              .toList() ??
          [],
      ukPrices: (map['ukPrices'] as List? ?? [])
          .map((item) => RetailerPrice.fromMap(
                Map<String, dynamic>.from((item as Map?) ?? const {}),
              ))
          .toList(),
      euPrices: (map['euPrices'] as List? ?? [])
          .map((item) => ImportOption.fromMap(
                Map<String, dynamic>.from((item as Map?) ?? const {}),
              ))
          .toList(),
    );
  }

  double? get bestUkSinglePrice => _lowestPositive(
        ukPrices.map((p) => p.singlePriceValue),
        max: 500,
      );

  double? get bestUkBoxPrice => _lowestPositive(
        ukPrices.map((p) => p.boxPriceValue),
        max: 10000,
      );

  double? get bestEuSingleBasePrice => _lowestPositive(
        euPrices.map((p) => p.singleBasePriceValue),
        max: 500,
      );

  double? get bestEuBoxBasePrice => _lowestPositive(
        euPrices.map((p) => p.boxBasePriceValue),
        max: 10000,
      );

  double? get bestEuSingleLandedPrice {
    final base = bestEuSingleBasePrice;
    if (base == null) return null;
    return ImportCalculator.landed(base, importWeightGrams);
  }

  double? get bestEuBoxLandedPrice {
    final base = bestEuBoxBasePrice;
    if (base == null) return null;
    return ImportCalculator.landed(base, importBoxWeightGrams);
  }

  double? get bestUkPrice => bestUkSinglePrice;

  double? get bestEuPrice => bestEuSingleLandedPrice;

  double get savingsPerCigar {
    final uk = bestUkSinglePrice;
    final eu = bestEuSingleLandedPrice;
    if (uk == null || eu == null) return 0;
    return uk - eu;
  }

  double get savingsPerBox {
    final ukBox = bestUkBoxPrice;
    final euBox = bestEuBoxLandedPrice;

    if (ukBox != null && euBox != null) {
      return ukBox - euBox;
    }

    return savingsPerCigar * boxQuantity;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class RetailerPrice {
  final String retailer;
  final String price;
  final String previousPrice;
  final String boxPrice;
  final String previousBoxPrice;
  final String stock;
  final String url;
  final String boxUrl;

  const RetailerPrice({
    required this.retailer,
    required this.price,
    required this.previousPrice,
    required this.boxPrice,
    required this.previousBoxPrice,
    required this.stock,
    required this.url,
    required this.boxUrl,
  });

  double? get singlePriceValue => _parseMoney(price);

  double? get boxPriceValue => _parseMoney(boxPrice);

  Map<String, dynamic> toMap() {
    return {
      'retailer': retailer,
      'price': price,
      'previousPrice': previousPrice,
      'boxPrice': boxPrice,
      'previousBoxPrice': previousBoxPrice,
      'stock': stock,
      'url': url,
      'boxUrl': boxUrl,
    };
  }

  factory RetailerPrice.fromMap(Map<String, dynamic> map) {
    return RetailerPrice(
      retailer: (map['retailer'] ?? '').toString(),
      price: (map['price'] ?? '').toString(),
      previousPrice: (map['previousPrice'] ?? map['price'] ?? '').toString(),
      boxPrice: (map['boxPrice'] ?? '').toString(),
      previousBoxPrice:
          (map['previousBoxPrice'] ?? map['boxPrice'] ?? '').toString(),
      stock: (map['stock'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
      boxUrl: (map['boxUrl'] ?? '').toString(),
    );
  }
}

class ImportOption {
  final String retailer;
  final String price;
  final String cigarPrice;
  final String dutyVat;
  final String landedCost;
  final String savings;
  final String stock;
  final String url;
  final String boxPrice;
  final String previousBoxPrice;
  final String boxUrl;

  const ImportOption({
    required this.retailer,
    required this.price,
    required this.cigarPrice,
    required this.dutyVat,
    required this.landedCost,
    required this.savings,
    required this.stock,
    required this.url,
    required this.boxPrice,
    required this.previousBoxPrice,
    required this.boxUrl,
  });

  double? get singleBasePriceValue => _parseMoney(cigarPrice.isNotEmpty ? cigarPrice : price);

  double? get boxBasePriceValue => _parseMoney(boxPrice);

  Map<String, dynamic> toMap() {
    return {
      'retailer': retailer,
      'price': price,
      'cigarPrice': cigarPrice,
      'dutyVat': dutyVat,
      'landedCost': landedCost,
      'savings': savings,
      'stock': stock,
      'url': url,
      'boxPrice': boxPrice,
      'previousBoxPrice': previousBoxPrice,
      'boxUrl': boxUrl,
    };
  }

  factory ImportOption.fromMap(Map<String, dynamic> map) {
    return ImportOption(
      retailer: (map['retailer'] ?? '').toString(),
      price: (map['price'] ?? '').toString(),
      cigarPrice: (map['cigarPrice'] ?? map['price'] ?? '').toString(),
      dutyVat: (map['dutyVat'] ?? '').toString(),
      landedCost: (map['landedCost'] ?? '').toString(),
      savings: (map['savings'] ?? '').toString(),
      stock: (map['stock'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
      boxPrice: (map['boxPrice'] ?? '').toString(),
      previousBoxPrice:
          (map['previousBoxPrice'] ?? map['boxPrice'] ?? '').toString(),
      boxUrl: (map['boxUrl'] ?? '').toString(),
    );
  }
}

double? _parseMoney(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return null;

  final value = double.tryParse(cleaned);
  if (value == null || value <= 0) return null;

  return value;
}

double? _lowestPositive(Iterable<double?> values, {double? max}) {
  final valid = values.whereType<double>().where((value) {
    if (value <= 0) return false;
    if (max != null && value > max) return false;
    return true;
  }).toList();

  if (valid.isEmpty) return null;
  valid.sort();
  return valid.first;
}
