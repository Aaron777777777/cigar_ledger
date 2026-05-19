import 'package:cloud_firestore/cloud_firestore.dart';

class CigarLedgerAppConfig {
  final String weeklyPicksTitle;
  final String bestDealsTitle;
  final String moreDealsTitle;
  final String lockedEuPriceText;
  final String premiumSavingsText;
  final String nonPremiumBoxSavingsText;
  final String nonPremiumSingleSavingsText;
  final String premiumHeroTitle;
  final String premiumHeroSubtitle;
  final String premiumSectionTitle;
  final String premiumReviewTitle;
  final String premiumReviewSubtitle;
  final String premiumSupportTitle;
  final String premiumUnlockButtonText;
  final String premiumActiveText;
  final String premiumFeatureOneTitle;
  final String premiumFeatureOneText;
  final String premiumFeatureTwoTitle;
  final String premiumFeatureTwoText;
  final String premiumFeatureThreeTitle;
  final String premiumFeatureThreeText;
  final bool herfStationPromoEnabled;
  final String herfStationPromoTitle;
  final String herfStationPromoSubtitle;
  final String herfStationPromoButtonText;

  const CigarLedgerAppConfig({
    required this.weeklyPicksTitle,
    required this.bestDealsTitle,
    required this.moreDealsTitle,
    required this.lockedEuPriceText,
    required this.premiumSavingsText,
    required this.nonPremiumBoxSavingsText,
    required this.nonPremiumSingleSavingsText,
    required this.premiumHeroTitle,
    required this.premiumHeroSubtitle,
    required this.premiumSectionTitle,
    required this.premiumReviewTitle,
    required this.premiumReviewSubtitle,
    required this.premiumSupportTitle,
    required this.premiumUnlockButtonText,
    required this.premiumActiveText,
    required this.premiumFeatureOneTitle,
    required this.premiumFeatureOneText,
    required this.premiumFeatureTwoTitle,
    required this.premiumFeatureTwoText,
    required this.premiumFeatureThreeTitle,
    required this.premiumFeatureThreeText,
    required this.herfStationPromoEnabled,
    required this.herfStationPromoTitle,
    required this.herfStationPromoSubtitle,
    required this.herfStationPromoButtonText,
  });

  factory CigarLedgerAppConfig.defaults() {
    return const CigarLedgerAppConfig(
      weeklyPicksTitle: 'THIS WEEK’S PICKS',
      bestDealsTitle: 'THIS WEEK’S BEST DEALS',
      moreDealsTitle: 'More top deals',
      lockedEuPriceText: 'Unlock Pro for EU price',
      premiumSavingsText: 'Top value opportunity',
      nonPremiumBoxSavingsText: 'BIG BOX SAVINGS',
      nonPremiumSingleSavingsText: 'PRO SAVINGS VIEW',
      premiumHeroTitle: 'Stop overpaying for cigars',
      premiumHeroSubtitle:
          'See the real cheapest route — and exactly how much you save.',
      premiumSectionTitle: 'WHAT YOU SAVE WITH PRO',
      premiumReviewTitle: 'Leave a review',
      premiumReviewSubtitle:
          'Enjoying Cigar Ledger? Open the Play Store and leave a quick review.',
      premiumSupportTitle: 'SUPPORT CIGAR LEDGER',
      premiumUnlockButtonText: 'Unlock Pro',
      premiumActiveText: 'Pro Active',
      premiumFeatureOneTitle: 'Know instantly if EU is cheaper',
      premiumFeatureOneText: 'See the exact cheapest route before you buy.',
      premiumFeatureTwoTitle: 'See your real savings (after tax & duty)',
      premiumFeatureTwoText:
          'Know exactly how much you save per cigar and per box.',
      premiumFeatureThreeTitle: 'Find the best deals instantly',
      premiumFeatureThreeText:
          'See the top cigar deals ranked by real savings.',
      herfStationPromoEnabled: true,
      herfStationPromoTitle: 'Smoke it with others?',
      herfStationPromoSubtitle: 'Join a live lounge on Herf Station.',
      herfStationPromoButtonText: 'Open Herf Station',
    );
  }

  factory CigarLedgerAppConfig.fromMap(Map<String, dynamic> data) {
    final fallback = CigarLedgerAppConfig.defaults();

    return CigarLedgerAppConfig(
      weeklyPicksTitle:
          data['weeklyPicksTitle'] as String? ?? fallback.weeklyPicksTitle,
      bestDealsTitle:
          data['bestDealsTitle'] as String? ?? fallback.bestDealsTitle,
      moreDealsTitle:
          data['moreDealsTitle'] as String? ?? fallback.moreDealsTitle,
      lockedEuPriceText:
          data['lockedEuPriceText'] as String? ?? fallback.lockedEuPriceText,
      premiumSavingsText:
          data['premiumSavingsText'] as String? ?? fallback.premiumSavingsText,
      nonPremiumBoxSavingsText:
          data['nonPremiumBoxSavingsText'] as String? ??
              fallback.nonPremiumBoxSavingsText,
      nonPremiumSingleSavingsText:
          data['nonPremiumSingleSavingsText'] as String? ??
              fallback.nonPremiumSingleSavingsText,
      premiumHeroTitle:
          data['premiumHeroTitle'] as String? ?? fallback.premiumHeroTitle,
      premiumHeroSubtitle:
          data['premiumHeroSubtitle'] as String? ??
              fallback.premiumHeroSubtitle,
      premiumSectionTitle:
          data['premiumSectionTitle'] as String? ??
              fallback.premiumSectionTitle,
      premiumReviewTitle:
          data['premiumReviewTitle'] as String? ?? fallback.premiumReviewTitle,
      premiumReviewSubtitle:
          data['premiumReviewSubtitle'] as String? ??
              fallback.premiumReviewSubtitle,
      premiumSupportTitle:
          data['premiumSupportTitle'] as String? ??
              fallback.premiumSupportTitle,
      premiumUnlockButtonText:
          data['premiumUnlockButtonText'] as String? ??
              fallback.premiumUnlockButtonText,
      premiumActiveText:
          data['premiumActiveText'] as String? ?? fallback.premiumActiveText,
      premiumFeatureOneTitle:
          data['premiumFeatureOneTitle'] as String? ??
              fallback.premiumFeatureOneTitle,
      premiumFeatureOneText:
          data['premiumFeatureOneText'] as String? ??
              fallback.premiumFeatureOneText,
      premiumFeatureTwoTitle:
          data['premiumFeatureTwoTitle'] as String? ??
              fallback.premiumFeatureTwoTitle,
      premiumFeatureTwoText:
          data['premiumFeatureTwoText'] as String? ??
              fallback.premiumFeatureTwoText,
      premiumFeatureThreeTitle:
          data['premiumFeatureThreeTitle'] as String? ??
              fallback.premiumFeatureThreeTitle,
      premiumFeatureThreeText:
          data['premiumFeatureThreeText'] as String? ??
              fallback.premiumFeatureThreeText,
      herfStationPromoEnabled:
          data['herfStationPromoEnabled'] as bool? ??
              fallback.herfStationPromoEnabled,
      herfStationPromoTitle:
          data['herfStationPromoTitle'] as String? ??
              fallback.herfStationPromoTitle,
      herfStationPromoSubtitle:
          data['herfStationPromoSubtitle'] as String? ??
              fallback.herfStationPromoSubtitle,
      herfStationPromoButtonText:
          data['herfStationPromoButtonText'] as String? ??
              fallback.herfStationPromoButtonText,
    );
  }
}

class AppConfigService {
  const AppConfigService();

  Future<CigarLedgerAppConfig> loadCigarLedgerConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('cigar_ledger')
          .get(const GetOptions(source: Source.serverAndCache));

      final data = doc.data();

      if (data == null) {
        return CigarLedgerAppConfig.defaults();
      }

      return CigarLedgerAppConfig.fromMap(data);
    } catch (_) {
      return CigarLedgerAppConfig.defaults();
    }
  }
}