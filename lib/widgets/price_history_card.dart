PriceHistoryCard(prices: cigar.priceHistory)import 'package:flutter/material.dart';

class PriceHistoryCard extends StatelessWidget {
  final List<double> prices;
  final String title;

  const PriceHistoryCard({
    super.key,
    required this.prices,
    this.title = 'Price History',
  });

  @override
  Widget build(BuildContext context) {

    if (prices.isEmpty) {
      return const SizedBox.shrink();
    }

    final startPrice = prices.first;
    final endPrice = prices.last;
    final trend = endPrice - startPrice;
    final trendText = (trend < 0 ? '↓ ' : '↑ ') + '£${trend.abs().toStringAsFixed(2)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22D4AF37)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 16,
            children: prices.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final price = entry.value;
              return Text(
                'Month $index: £${price.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          Text(
            'Trend $trendText',
            style: TextStyle(
              color: trend < 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
