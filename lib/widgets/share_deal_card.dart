import 'package:flutter/material.dart';

class ShareDealCard extends StatelessWidget {
  final String cigarName;
  final String brand;
  final String ukPrice;
  final String euPrice;
  final String cigarSaving;
  final String boxSaving;

  const ShareDealCard({
    super.key,
    required this.cigarName,
    required this.brand,
    required this.ukPrice,
    required this.euPrice,
    required this.cigarSaving,
    required this.boxSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 720,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0x44D4AF37),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 30,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Color(0x18D4AF37),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CIGAR LEDGER',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Price intelligence for cigar buyers',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            height: 1,
            color: const Color(0x22D4AF37),
          ),
          const SizedBox(height: 30),
          Text(
            cigarName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            brand,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0x14141414),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x22D4AF37)),
            ),
            child: Column(
              children: [
                _row('Best UK price', ukPrice),
                const SizedBox(height: 14),
                _row('Best EU landed', euPrice),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0x22D4AF37),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0x66D4AF37)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BEST DEAL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'SAVE $boxSaving PER BOX',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$cigarSaving per cigar',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shared from Cigar Ledger',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
              Text(
                'UK vs EU cigar deals',
                style: TextStyle(
                  color: Color(0x88D4AF37),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}