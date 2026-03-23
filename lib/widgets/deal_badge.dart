import 'package:flutter/material.dart';

class DealBadge extends StatelessWidget {
  final String? label;
  final double? boxSaving;
  final bool hasImportData;

  const DealBadge({
    super.key,
    this.label,
    this.boxSaving,
    this.hasImportData = true,
  });

  @override
  Widget build(BuildContext context) {
    String? resolvedLabel = label;

    // If no manual label was passed, derive one from saving data
    if (resolvedLabel == null) {
      if (!hasImportData || boxSaving == null) {
        return const SizedBox.shrink();
      }

      final saving = boxSaving!;

      if (saving >= 150) {
        resolvedLabel = 'HOT DEAL';
      } else if (saving >= 75) {
        resolvedLabel = 'BOX VALUE';
      } else if (saving >= 50) {
        resolvedLabel = 'GOOD IMPORT';
      } else if (saving >= 30) {
        resolvedLabel = 'BORDERLINE';
      } else {
        return const SizedBox.shrink();
      }
    }

    final style = _styleForLabel(resolvedLabel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: style.borderColor,
          width: 1,
        ),
      ),
      child: Text(
        resolvedLabel,
        style: TextStyle(
          color: style.textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  _DealBadgeStyle _styleForLabel(String label) {
    switch (label.toUpperCase()) {
      case 'HOT DEAL':
        return _DealBadgeStyle(
          backgroundColor: const Color(0x22D4AF37),
          borderColor: const Color(0x66D4AF37),
          textColor: const Color(0xFFD4AF37),
        );

      case 'BOX VALUE':
        return _DealBadgeStyle(
          backgroundColor: const Color(0x1FD4AF37),
          borderColor: const Color(0x55D4AF37),
          textColor: const Color(0xFFE7C65A),
        );

      case 'GOOD IMPORT':
      case 'BEST IMPORT':
        return _DealBadgeStyle(
          backgroundColor: const Color(0x1F3DDC97),
          borderColor: const Color(0x553DDC97),
          textColor: const Color(0xFF7EF0BD),
        );

      case 'BORDERLINE':
        return _DealBadgeStyle(
          backgroundColor: const Color(0x1FFFFFFF),
          borderColor: const Color(0x33FFFFFF),
          textColor: const Color(0xFFD0D0D0),
        );

      case 'BUY IN UK':
      case 'NO IMPORT DATA':
      case 'NO DATA':
        return _DealBadgeStyle(
          backgroundColor: const Color(0x14FFFFFF),
          borderColor: const Color(0x24FFFFFF),
          textColor: const Color(0xFFB0B0B0),
        );

      default:
        return _DealBadgeStyle(
          backgroundColor: const Color(0x18D4AF37),
          borderColor: const Color(0x40D4AF37),
          textColor: const Color(0xFFD4AF37),
        );
    }
  }
}

class _DealBadgeStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  _DealBadgeStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}