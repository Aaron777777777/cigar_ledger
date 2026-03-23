import 'package:flutter/material.dart';

class LedgerFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const LedgerFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,

          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),

            color: isSelected
                ? const Color(0xFFD4AF37)
                : const Color(0xFF171717),

            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD4AF37)
                  : const Color(0x33D4AF37),
              width: 1,
            ),

            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),

          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF111111)
                  : Colors.white.withOpacity(0.75),

              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.25,
            ),
          ),
        ),
      ),
    );
  }
}