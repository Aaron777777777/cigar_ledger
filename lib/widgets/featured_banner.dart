import 'dart:ui';

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/price_mode.dart';
import '../models/cigar.dart';

class FeaturedBanner extends StatelessWidget {
  final Cigar cigar;
  final String bestUkPrice;
  final String saving;
  final VoidCallback onTap;

  const FeaturedBanner({
    super.key,
    required this.cigar,
    required this.bestUkPrice,
    required this.saving,
    required this.onTap,
  });

  double _value(String price) {
    return double.tryParse(price.replaceAll('£', '').trim()) ?? 0;
  }

  String _format(double value) => '£${value.toStringAsFixed(2)}';

  String _safePerCigarPrice(String price) {
    final value = _value(price);
    if (value <= 0 || value > 200) return '£0.00';
    return price.startsWith('£') ? price : _format(value);
  }

  String _safeSaving(String price) {
    final value = _value(price);
    if (value <= 0 || value > 200) return '£0.00';
    return price.startsWith('£') ? price : _format(value);
  }

  @override
  Widget build(BuildContext context) {
    final safeUkPrice = _safePerCigarPrice(bestUkPrice);
    final safeSaving = _safeSaving(saving);

    final ukValue = _value(safeUkPrice);
    final savingValue = _value(safeSaving);

    return AnimatedBuilder(
      animation: priceMode,
      builder: (context, _) {
        final showBox = priceMode.showBoxPrice;

        final displayedUk = showBox
            ? '${_format(ukValue * cigar.boxQuantity)} / box'
            : safeUkPrice;

        final displayedSaving = showBox
            ? '£${(savingValue * cigar.boxQuantity).toStringAsFixed(0)} per box'
            : '$safeSaving per cigar';

        return Container(
          margin: const EdgeInsets.only(bottom: 28),
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
                      Color(0xD9161616),
                      Color(0xC9131313),
                    ],
                  ),
                  border: Border.all(color: AppColors.borderGoldMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.10),
                      blurRadius: 36,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BEST SAVINGS TODAY',
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              color: AppColors.gold,
                              letterSpacing: 1.4,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            cigar.name,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cigar.brand,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: _FeaturedMetric(
                                  label: showBox ? 'Best UK box' : 'Best UK',
                                  value: displayedUk,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _FeaturedMetric(
                                  label: 'Save up to',
                                  value: displayedSaving,
                                  gold: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'View best opportunity',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppColors.gold,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

class _FeaturedMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;

  const _FeaturedMetric({
    required this.label,
    required this.value,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: gold ? AppColors.glassGold : AppColors.glassStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderGoldSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: gold ? AppColors.gold : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
