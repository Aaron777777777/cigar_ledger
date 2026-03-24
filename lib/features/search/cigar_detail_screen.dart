import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/import_calculator.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cigar.dart';
import '../../services/purchase_service.dart';
import '../../services/watchlist_service.dart';
import '../../widgets/deal_badge.dart';
import '../premium/premium_screen.dart';

class CigarDetailScreen extends StatelessWidget {
  final Cigar cigar;

  const CigarDetailScreen({
    super.key,
    required this.cigar,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseService>().isPremium;
    final watchlist = context.watch<WatchlistService>();
    final isSaved = watchlist.isSaved(cigar);

    final singleWeight = cigar.importWeightGrams;
    final boxWeight = cigar.importBoxWeightGrams;

    final bestUkSingle = _bestUkSingle(cigar.ukPrices);
    final bestEuSingle = _bestEuSingle(cigar.euPrices);
    final bestUkBox = _bestUkBox(cigar.ukPrices);
    final bestEuBox = _bestEuBox(cigar.euPrices);

    final ukSinglePrice = bestUkSingle?.singlePriceValue;
    final euSingleBase = bestEuSingle?.singleBasePriceValue;
    final singleDuty =
        euSingleBase != null ? ImportCalculator.duty(singleWeight) : null;
    final singleVat = (euSingleBase != null && singleDuty != null)
        ? ImportCalculator.vat(euSingleBase, singleDuty)
        : null;
    final singleLanded =
        (euSingleBase != null && singleDuty != null && singleVat != null)
            ? euSingleBase + singleDuty + singleVat
            : null;
    final singleSaving = (ukSinglePrice != null && singleLanded != null)
        ? ukSinglePrice - singleLanded
        : null;
    final singleImportCheaper = singleSaving != null && singleSaving > 0;

    final ukBoxPrice = bestUkBox?.boxPriceValue;
    final euBoxBase = bestEuBox?.boxBasePriceValue;
    final boxDuty = euBoxBase != null ? ImportCalculator.duty(boxWeight) : null;
    final boxVat = (euBoxBase != null && boxDuty != null)
        ? ImportCalculator.vat(euBoxBase, boxDuty)
        : null;
    final boxLanded = (euBoxBase != null && boxDuty != null && boxVat != null)
        ? euBoxBase + boxDuty + boxVat
        : null;
    final boxSaving =
        (ukBoxPrice != null && boxLanded != null) ? ukBoxPrice - boxLanded : null;
    final boxSavingPerCigar =
        (boxSaving != null && cigar.boxQuantity > 0)
            ? boxSaving / cigar.boxQuantity
            : null;
    final boxImportCheaper = boxSaving != null && boxSaving > 0;

    final preferBoxHeadline = ukBoxPrice != null || boxLanded != null;
    final headlineImportCheaper =
        preferBoxHeadline ? boxImportCheaper : singleImportCheaper;
    final headlineRetailer = _headlineRetailer(
      preferBox: preferBoxHeadline,
      importCheaper: headlineImportCheaper,
      bestUkSingle: bestUkSingle,
      bestEuSingle: bestEuSingle,
      bestUkBox: bestUkBox,
      bestEuBox: bestEuBox,
    );
    final headlineUrl = _headlineUrl(
      preferBox: preferBoxHeadline,
      importCheaper: headlineImportCheaper,
      bestUkSingle: bestUkSingle,
      bestEuSingle: bestEuSingle,
      bestUkBox: bestUkBox,
      bestEuBox: bestEuBox,
    );
    final headlineButtonRetailer = _headlineButtonRetailer(
      preferBox: preferBoxHeadline,
      importCheaper: headlineImportCheaper,
      bestUkSingle: bestUkSingle,
      bestEuSingle: bestEuSingle,
      bestUkBox: bestUkBox,
      bestEuBox: bestEuBox,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CIGAR LEDGER'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () async {
                final wasSaved = isSaved;
                await context.read<WatchlistService>().toggle(cigar);

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      wasSaved
                          ? 'Removed from watchlist'
                          : 'Added to watchlist',
                    ),
                    duration: const Duration(milliseconds: 1100),
                  ),
                );
              },
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1B1B1D),
                  border: Border.all(
                    color: const Color(0x33D4AF37),
                  ),
                ),
                child: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: isSaved
                      ? const Color(0xFFD4AF37)
                      : const Color(0x66D4AF37),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF090909),
              Color(0xFF0D0D0E),
              Color(0xFF111111),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildCigarImage(cigar.imageUrl)),
              const SizedBox(height: 28),
              Text(
                cigar.name,
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cigar.brand,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(cigar.country),
                  _chip('${cigar.ringGauge} Ring'),
                  _chip(cigar.strength),
                  _chip('${cigar.boxQuantity} / box'),
                  _chip('${singleWeight.toStringAsFixed(1)}g est.'),
                ],
              ),
              const SizedBox(height: 30),
              if (!isPremium)
                _buildLockedCard(
                  ukSinglePrice: ukSinglePrice,
                  ukBoxPrice: ukBoxPrice,
                  hasEachImport: singleLanded != null,
                  hasBoxImport: boxLanded != null,
                  context: context,
                )
              else
                _buildPremiumCard(
                  headlineImportCheaper: headlineImportCheaper,
                  headlineRetailer: headlineRetailer,
                  headlineUrl: headlineUrl,
                  headlineButtonRetailer: headlineButtonRetailer,
                  ukSinglePrice: ukSinglePrice,
                  euSingleBase: euSingleBase,
                  singleDuty: singleDuty,
                  singleVat: singleVat,
                  singleLanded: singleLanded,
                  singleSaving: singleSaving,
                  ukBoxPrice: ukBoxPrice,
                  euBoxBase: euBoxBase,
                  boxDuty: boxDuty,
                  boxVat: boxVat,
                  boxLanded: boxLanded,
                  boxSaving: boxSaving,
                  boxSavingPerCigar: boxSavingPerCigar,
                  singleImportCheaper: singleImportCheaper,
                  boxImportCheaper: boxImportCheaper,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedCard({
    required BuildContext context,
    required double? ukSinglePrice,
    required double? ukBoxPrice,
    required bool hasEachImport,
    required bool hasBoxImport,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF0141416),
            Color(0xEE0E0E10),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGoldMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              DealBadge(label: 'PRO'),
              SizedBox(width: 10),
              Text(
                'UNLOCK THE BEST DEAL',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (ukSinglePrice != null) ...[
            const Text(
              'PER CIGAR',
              style: TextStyle(
                color: AppColors.textSecondary,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _priceRow('UK price', '£${ukSinglePrice.toStringAsFixed(2)}'),
            if (hasEachImport) const _LockedPriceRow(label: 'EU landed'),
            const SizedBox(height: 14),
          ],
          if (ukBoxPrice != null) ...[
            const Text(
              'PER BOX',
              style: TextStyle(
                color: AppColors.textSecondary,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _priceRow('UK box', '£${ukBoxPrice.toStringAsFixed(2)}'),
            if (hasBoxImport) const _LockedPriceRow(label: 'EU landed box'),
            const SizedBox(height: 18),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.glassStrong,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'See real each and box comparisons',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Unlock UK vs EU landed pricing, duty, VAT, box savings, and direct buy links.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PremiumScreen(),
                  ),
                );
              },
              child: const Text(
                'Unlock Pro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({
    required bool headlineImportCheaper,
    required String headlineRetailer,
    required String headlineUrl,
    required String headlineButtonRetailer,
    required double? ukSinglePrice,
    required double? euSingleBase,
    required double? singleDuty,
    required double? singleVat,
    required double? singleLanded,
    required double? singleSaving,
    required double? ukBoxPrice,
    required double? euBoxBase,
    required double? boxDuty,
    required double? boxVat,
    required double? boxLanded,
    required double? boxSaving,
    required double? boxSavingPerCigar,
    required bool singleImportCheaper,
    required bool boxImportCheaper,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF0141416),
            Color(0xEE0E0E10),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGoldMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DealBadge(label: headlineImportCheaper ? 'IMPORT LIVE' : 'UK LIVE'),
              const SizedBox(width: 10),
              const Text(
                'UK VS EU LANDED',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (headlineRetailer.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Cheapest current retailer',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              headlineRetailer.trim().toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (ukSinglePrice != null || singleLanded != null) ...[
            const SizedBox(height: 22),
            const Divider(color: Colors.white12),
            const SizedBox(height: 18),
            const Text(
              'PER CIGAR',
              style: TextStyle(
                color: AppColors.textSecondary,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (ukSinglePrice != null)
              _priceRow('UK price', '£${ukSinglePrice.toStringAsFixed(2)}'),
            if (singleLanded != null)
              _priceRow('EU landed', '£${singleLanded.toStringAsFixed(2)}'),
            const SizedBox(height: 14),
            _summaryBanner(
              highlight: singleImportCheaper,
              title: singleSaving == null
                  ? 'No import pricing available'
                  : singleImportCheaper
                      ? 'SAVE £${singleSaving.toStringAsFixed(2)} PER CIGAR'
                      : 'UK IS CHEAPER PER CIGAR',
              subtitle: singleSaving == null
                  ? 'Add or check EU single pricing for this cigar.'
                  : singleImportCheaper
                      ? 'Import is currently cheaper on the single-cigar maths.'
                      : 'Import costs £${singleSaving.abs().toStringAsFixed(2)} more per cigar.',
            ),
            if (euSingleBase != null || singleDuty != null || singleVat != null) ...[
              const SizedBox(height: 18),
              const Text(
                'IMPORT BREAKDOWN (PER CIGAR)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (euSingleBase != null)
                _priceRow('EU price', '£${euSingleBase.toStringAsFixed(2)}'),
              if (singleDuty != null)
                _priceRow('Duty', '£${singleDuty.toStringAsFixed(2)}'),
              if (singleVat != null)
                _priceRow('VAT', '£${singleVat.toStringAsFixed(2)}'),
            ],
          ],
          if (ukBoxPrice != null || boxLanded != null) ...[
            const SizedBox(height: 22),
            const Divider(color: Colors.white12),
            const SizedBox(height: 18),
            const Text(
              'PER BOX',
              style: TextStyle(
                color: AppColors.textSecondary,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (ukBoxPrice != null)
              _priceRow('UK box', '£${ukBoxPrice.toStringAsFixed(2)}'),
            if (boxLanded != null)
              _priceRow('EU landed box', '£${boxLanded.toStringAsFixed(2)}'),
            const SizedBox(height: 14),
            _summaryBanner(
              highlight: boxImportCheaper,
              title: boxSaving == null
                  ? 'No box import pricing available'
                  : boxImportCheaper
                      ? 'SAVE £${boxSaving.toStringAsFixed(0)} PER BOX'
                      : 'UK IS CHEAPER PER BOX',
              subtitle: boxSaving == null
                  ? 'Add or check EU box pricing for this cigar.'
                  : boxImportCheaper
                      ? '£${(boxSavingPerCigar ?? 0).toStringAsFixed(2)} saving per cigar across the box.'
                      : 'Import costs £${boxSaving.abs().toStringAsFixed(2)} more per box.',
            ),
            if (euBoxBase != null || boxDuty != null || boxVat != null) ...[
              const SizedBox(height: 18),
              const Text(
                'IMPORT BREAKDOWN (PER BOX)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (euBoxBase != null)
                _priceRow('EU box price', '£${euBoxBase.toStringAsFixed(2)}'),
              if (boxDuty != null)
                _priceRow('Duty', '£${boxDuty.toStringAsFixed(2)}'),
              if (boxVat != null)
                _priceRow('VAT', '£${boxVat.toStringAsFixed(2)}'),
            ],
          ],
          const SizedBox(height: 18),
          const Text(
            'Estimated using UK cigar duty + VAT. Weight is estimated from cigar size when exact weight is unavailable.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          if (headlineUrl.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buyButton(
              label: 'Buy from $headlineButtonRetailer',
              url: headlineUrl,
            ),
          ],
        ],
      ),
    );
  }

  static RetailerPrice? _bestUkSingle(List<RetailerPrice> prices) {
    final valid = prices.where((p) => (p.singlePriceValue ?? 0) > 0).toList();
    if (valid.isEmpty) return null;
    valid.sort(
      (a, b) =>
          (a.singlePriceValue ?? 999999).compareTo(b.singlePriceValue ?? 999999),
    );
    return valid.first;
  }

  static ImportOption? _bestEuSingle(List<ImportOption> prices) {
    final valid = prices.where((p) => (p.singleBasePriceValue ?? 0) > 0).toList();
    if (valid.isEmpty) return null;
    valid.sort(
      (a, b) => (a.singleBasePriceValue ?? 999999)
          .compareTo(b.singleBasePriceValue ?? 999999),
    );
    return valid.first;
  }

  static RetailerPrice? _bestUkBox(List<RetailerPrice> prices) {
    final valid = prices.where((p) => (p.boxPriceValue ?? 0) > 0).toList();
    if (valid.isEmpty) return null;
    valid.sort(
      (a, b) =>
          (a.boxPriceValue ?? 999999).compareTo(b.boxPriceValue ?? 999999),
    );
    return valid.first;
  }

  static ImportOption? _bestEuBox(List<ImportOption> prices) {
    final valid = prices.where((p) => (p.boxBasePriceValue ?? 0) > 0).toList();
    if (valid.isEmpty) return null;
    valid.sort(
      (a, b) =>
          (a.boxBasePriceValue ?? 999999).compareTo(b.boxBasePriceValue ?? 999999),
    );
    return valid.first;
  }

  static String _headlineRetailer({
    required bool preferBox,
    required bool importCheaper,
    required RetailerPrice? bestUkSingle,
    required ImportOption? bestEuSingle,
    required RetailerPrice? bestUkBox,
    required ImportOption? bestEuBox,
  }) {
    final raw = preferBox
        ? (importCheaper ? bestEuBox?.retailer : bestUkBox?.retailer)
        : (importCheaper ? bestEuSingle?.retailer : bestUkSingle?.retailer);

    return (raw ?? '').trim();
  }

  static String _headlineButtonRetailer({
    required bool preferBox,
    required bool importCheaper,
    required RetailerPrice? bestUkSingle,
    required ImportOption? bestEuSingle,
    required RetailerPrice? bestUkBox,
    required ImportOption? bestEuBox,
  }) {
    final raw = preferBox
        ? (importCheaper ? bestEuBox?.retailer : bestUkBox?.retailer)
        : (importCheaper ? bestEuSingle?.retailer : bestUkSingle?.retailer);

    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) return 'retailer';
    if (trimmed.length <= 4) return trimmed.toUpperCase();
    return trimmed;
  }

  static String _headlineUrl({
    required bool preferBox,
    required bool importCheaper,
    required RetailerPrice? bestUkSingle,
    required ImportOption? bestEuSingle,
    required RetailerPrice? bestUkBox,
    required ImportOption? bestEuBox,
  }) {
    if (preferBox) {
      if (importCheaper) {
        final boxUrl = bestEuBox?.boxUrl.trim() ?? '';
        if (boxUrl.isNotEmpty) return boxUrl;
        return bestEuBox?.url.trim() ?? '';
      }

      final boxUrl = bestUkBox?.boxUrl.trim() ?? '';
      if (boxUrl.isNotEmpty) return boxUrl;
      return bestUkBox?.url.trim() ?? '';
    }

    if (importCheaper) {
      return bestEuSingle?.url.trim() ?? '';
    }

    return bestUkSingle?.url.trim() ?? '';
  }

  Widget _buildCigarImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return _imageFallback();
    }

    final isRemote =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0x1FFFFFFF),
            Color(0x0DFFFFFF),
          ],
        ),
        border: Border.all(color: const Color(0x22D4AF37)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: isRemote
            ? Image.network(
                imageUrl,
                height: 240,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _imageFallback(),
              )
            : Image.asset(
                imageUrl,
                height: 240,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _imageFallback(),
              ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 240,
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Icon(
          Icons.smoking_rooms,
          size: 42,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGoldSoft),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  static Widget _summaryBanner({
    required bool highlight,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppColors.goldTint : AppColors.glassStrong,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppColors.borderGoldMedium
              : Colors.white.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.gold : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  static Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Widget _buyButton({
    required String label,
    required String url,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        onPressed: () async {
          final uri = Uri.parse(url);
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            throw Exception('Could not launch $uri');
          }
        },
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _LockedPriceRow extends StatelessWidget {
  final String label;

  const _LockedPriceRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Premium',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}