import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/price_mode.dart';
import '../core/theme/app_theme.dart';
import '../models/cigar.dart';
import '../services/purchase_service.dart';

class CigarSearchCard extends StatelessWidget {
  final Cigar cigar;
  final VoidCallback onTap;
  final int? rank;
  final String dealStrength;
  final double ukSinglePrice;
  final double euSinglePrice;
  final double ukBoxPrice;
  final double euBoxPrice;
  final double savingPerCigar;
  final double savingPerBox;
  final String lockedEuPriceText;

  const CigarSearchCard({
    super.key,
    required this.cigar,
    required this.onTap,
    this.rank,
    this.dealStrength = 'TOP',
    this.ukSinglePrice = 0,
    this.euSinglePrice = 0,
    this.ukBoxPrice = 0,
    this.euBoxPrice = 0,
    this.savingPerCigar = 0,
    this.savingPerBox = 0,
    this.lockedEuPriceText = 'Unlock Pro for EU price',
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseService>().isPremium;

    return AnimatedBuilder(
      animation: priceMode,
      builder: (context, _) {
        final showBox = priceMode.showBoxPrice;

        final ukDisplayValue = showBox ? ukBoxPrice : ukSinglePrice;
        final euDisplayValue = showBox ? euBoxPrice : euSinglePrice;
        final hasCurrentModeComparison =
            ukDisplayValue > 0 && euDisplayValue > 0;
        final hasImportAdvantage =
            hasCurrentModeComparison && euDisplayValue < ukDisplayValue;

        if (!hasCurrentModeComparison) {
          return const SizedBox.shrink();
        }

        final ukDisplay = '£${ukDisplayValue.toStringAsFixed(2)}';
        final euDisplay = '£${euDisplayValue.toStringAsFixed(2)}';

        final savingText = showBox
            ? 'SAVE £${savingPerBox.toStringAsFixed(0)} PER BOX'
            : 'SAVE £${savingPerCigar.toStringAsFixed(2)} PER CIGAR';

        return Container(
          margin: const EdgeInsets.only(bottom: 22),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xF0141416),
                      Color(0xEE0E0E10),
                      Color(0xF0101012),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0x26D4AF37),
                    width: 1.1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              rank != null ? '#$rank' : 'DEAL',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dealStrength.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ImageFrame(imageUrl: cigar.imageUrl),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cigar.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cigar.brand,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricBox(
                              label: showBox ? 'Best UK box' : 'Best UK',
                              value: ukDisplay,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: isPremium
                                ? _MetricBox(
                                    label: showBox
                                        ? 'EU landed box'
                                        : 'EU landed',
                                    value: euDisplay,
                                    goldValue: hasImportAdvantage,
                                  )
                                : _LockedMetricBox(
                                    label: showBox
                                        ? 'EU landed box'
                                        : 'EU landed',
                                    lockedEuPriceText: lockedEuPriceText,
                                  ),
                          ),
                        ],
                      ),
                      if (isPremium && hasImportAdvantage) ...[
                        const SizedBox(height: 14),
                        Text(
                          savingText,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImageFrame extends StatelessWidget {
  final String imageUrl;

  const _ImageFrame({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 160,
      child: Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.smoking_rooms, color: Colors.white54),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final bool goldValue;

  const _MetricBox({
    required this.label,
    required this.value,
    this.goldValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0x1EFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: goldValue ? AppColors.gold : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedMetricBox extends StatelessWidget {
  final String label;
  final String lockedEuPriceText;

  const _LockedMetricBox({
    required this.label,
    required this.lockedEuPriceText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0x1EFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            lockedEuPriceText,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}