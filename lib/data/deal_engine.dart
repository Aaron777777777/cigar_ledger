import '../models/cigar.dart';
import '../core/import_calculator.dart';

class DealResult {
  final Cigar cigar;
  final double ukBestBoxPrice;
  final double euBestBoxPrice;
  final double ukBestSinglePrice;
  final double euBestSinglePrice;
  final double savingPerCigar;
  final double boxSavingPerCigar;
  final double savingPerBox;
  final double dealScore;
  final String dealStrength;
  final String decisionLabel;

  DealResult({
    required this.cigar,
    required this.ukBestBoxPrice,
    required this.euBestBoxPrice,
    required this.ukBestSinglePrice,
    required this.euBestSinglePrice,
    required this.savingPerCigar,
    required this.boxSavingPerCigar,
    required this.savingPerBox,
    required this.dealScore,
    required this.dealStrength,
    required this.decisionLabel,
  });

  double get ukBestPrice => ukBestBoxPrice;

  double get euBestPrice => euBestBoxPrice;
}

class DealEngine {
  static const double maxSingleCigarUkPrice = 150;
  static const double maxSingleCigarEuPrice = 150;
  static const double maxBoxUkPrice = 10000;
  static const double maxBoxEuPrice = 10000;
  static const double minimumBoxSaving = 50;

  static List<DealResult> biggestSavings(List<Cigar> cigars) {
    final results = cigars
        .where((cigar) =>
            cigar.name.trim().isNotEmpty &&
            cigar.imageUrl.trim().isNotEmpty &&
            cigar.boxQuantity > 0)
        .map(calculateDeal)
        .where(
          (deal) =>
              deal.ukBestBoxPrice > 0 &&
              deal.euBestBoxPrice > 0 &&
              deal.savingPerBox >= minimumBoxSaving,
        )
        .toList();

    results.sort((a, b) {
      final boxCompare = b.savingPerBox.compareTo(a.savingPerBox);
      if (boxCompare != 0) return boxCompare;
      return b.dealScore.compareTo(a.dealScore);
    });

    return results;
  }
}

DealResult calculateDeal(Cigar cigar) {
  final ukBestSinglePrice = _lowestUkSinglePrice(cigar);
  final euBestSinglePrice = _lowestEuSingleLandedPrice(cigar);
  final ukBestBoxPrice = _lowestUkBoxPrice(cigar);
  final euBestBoxPrice = _lowestEuBoxLandedPrice(cigar);

  final hasSingleImportAdvantage =
      ukBestSinglePrice > 0 &&
      euBestSinglePrice > 0 &&
      euBestSinglePrice < ukBestSinglePrice;
  final hasBoxImportAdvantage =
      ukBestBoxPrice > 0 && euBestBoxPrice > 0 && euBestBoxPrice < ukBestBoxPrice;

  final savingPerCigar =
      hasSingleImportAdvantage ? ukBestSinglePrice - euBestSinglePrice : 0.0;
  final savingPerBox = hasBoxImportAdvantage ? ukBestBoxPrice - euBestBoxPrice : 0.0;
  final boxSavingPerCigar =
      cigar.boxQuantity > 0 ? savingPerBox / cigar.boxQuantity : 0.0;

  final dealScore = _calculateDealScore(
    ukPrice: ukBestBoxPrice,
    euPrice: euBestBoxPrice,
    boxQuantity: cigar.boxQuantity,
  );

  final dealStrength = _dealStrengthFromBoxSaving(savingPerBox);

  final decisionLabel = _decisionLabel(
    ukPrice: ukBestBoxPrice,
    euPrice: euBestBoxPrice,
    savingPerBox: savingPerBox,
  );

  return DealResult(
    cigar: cigar,
    ukBestBoxPrice: ukBestBoxPrice,
    euBestBoxPrice: euBestBoxPrice,
    ukBestSinglePrice: ukBestSinglePrice,
    euBestSinglePrice: euBestSinglePrice,
    savingPerCigar: savingPerCigar,
    boxSavingPerCigar: boxSavingPerCigar,
    savingPerBox: savingPerBox,
    dealScore: dealScore,
    dealStrength: dealStrength,
    decisionLabel: decisionLabel,
  );
}

double _lowestUkSinglePrice(Cigar cigar) {
  double best = 0;

  for (final option in cigar.ukPrices) {
    final parsed = _parseMoney(option.price);
    if (parsed == null) continue;
    if (parsed <= 0 || parsed > DealEngine.maxSingleCigarUkPrice) continue;

    if (best == 0 || parsed < best) {
      best = parsed;
    }
  }

  return best;
}

double _lowestEuSingleLandedPrice(Cigar cigar) {
  double best = 0;

  for (final option in cigar.euPrices) {
    final euBasePrice = _parseMoney(
      option.cigarPrice.isNotEmpty ? option.cigarPrice : option.price,
    );

    if (euBasePrice == null) continue;
    if (euBasePrice <= 0 || euBasePrice > DealEngine.maxSingleCigarEuPrice) {
      continue;
    }

    final landed = ImportCalculator.landed(euBasePrice, cigar.importWeightGrams);
    if (landed <= 0 || landed > DealEngine.maxSingleCigarEuPrice) continue;

    if (best == 0 || landed < best) {
      best = landed;
    }
  }

  return best;
}

double _lowestUkBoxPrice(Cigar cigar) {
  double best = 0;

  for (final option in cigar.ukPrices) {
    final parsed = _parseMoney(option.boxPrice);
    if (parsed == null) continue;
    if (parsed <= 0 || parsed > DealEngine.maxBoxUkPrice) continue;

    if (best == 0 || parsed < best) {
      best = parsed;
    }
  }

  return best;
}

double _lowestEuBoxLandedPrice(Cigar cigar) {
  double best = 0;

  for (final option in cigar.euPrices) {
    final euBoxPrice = _parseMoney(option.boxPrice);
    if (euBoxPrice == null) continue;
    if (euBoxPrice <= 0 || euBoxPrice > DealEngine.maxBoxEuPrice) continue;

    final landed = ImportCalculator.boxLanded(
      euBoxPrice,
      cigar.importWeightGrams,
      cigar.boxQuantity,
    );

    if (landed <= 0 || landed > DealEngine.maxBoxEuPrice) continue;

    if (best == 0 || landed < best) {
      best = landed;
    }
  }

  return best;
}

double _calculateDealScore({
  required double ukPrice,
  required double euPrice,
  required int boxQuantity,
}) {
  if (ukPrice <= 0 || euPrice <= 0 || euPrice >= ukPrice) {
    return 0;
  }

  final savingPerBox = ukPrice - euPrice;
  final savingPerCigar = boxQuantity > 0 ? savingPerBox / boxQuantity : 0;
  final savingPercent = (savingPerBox / ukPrice) * 100;

  double score = 0;
  score += savingPercent * 1.8;
  score += savingPerBox / 10;
  score += savingPerCigar * 2;

  if (savingPerBox >= 150) score += 5;
  if (savingPerBox >= 200) score += 8;
  if (savingPerBox >= 300) score += 6;

  if (score > 100) score = 100;

  return score;
}

String _dealStrengthFromBoxSaving(double savingPerBox) {
  if (savingPerBox >= 250) return 'EXCEPTIONAL';
  if (savingPerBox >= 175) return 'EXCELLENT';
  if (savingPerBox >= 100) return 'STRONG';
  if (savingPerBox >= 75) return 'GOOD';
  if (savingPerBox >= 50) return 'DECENT';
  return 'WEAK';
}

String _decisionLabel({
  required double ukPrice,
  required double euPrice,
  required double savingPerBox,
}) {
  if (ukPrice <= 0 || euPrice <= 0) return 'NO DATA';
  if (euPrice >= ukPrice) return 'BUY IN UK';
  if (savingPerBox >= 150) return 'EXCELLENT IMPORT DEAL';
  if (savingPerBox >= 100) return 'WORTH IMPORTING';
  if (savingPerBox >= 50) return 'GOOD IMPORT DEAL';
  return 'BORDERLINE';
}

double? _parseMoney(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}
