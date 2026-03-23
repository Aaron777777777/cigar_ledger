import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ImportCalculatorCard extends StatefulWidget {
  final String bestUkPrice;
  final double? initialPrice;
  final double? initialShipping;

  const ImportCalculatorCard({
    super.key,
    required this.bestUkPrice,
    this.initialPrice,
    this.initialShipping,
  });

  @override
  State<ImportCalculatorCard> createState() => _ImportCalculatorCardState();
}

class _ImportCalculatorCardState extends State<ImportCalculatorCard> {
  late TextEditingController cigarPriceController;
  late TextEditingController shippingController;
  final TextEditingController quantityController =
      TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();

    cigarPriceController = TextEditingController(
      text: widget.initialPrice?.toString() ?? '24.50',
    );

    shippingController = TextEditingController(
      text: widget.initialShipping?.toString() ?? '6.00',
    );
  }

  double get cigarPrice =>
      double.tryParse(cigarPriceController.text.trim()) ?? 0;

  double get shipping =>
      double.tryParse(shippingController.text.trim()) ?? 0;

  int get quantity =>
      int.tryParse(quantityController.text.trim()) ?? 1;

  double get subtotal => (cigarPrice * quantity) + shipping;

  double get duty => subtotal * 0.18;

  double get vat => (subtotal + duty) * 0.20;

  double get landedCost => subtotal + duty + vat;

  double get bestUk =>
      double.tryParse(widget.bestUkPrice.replaceAll('£', '').trim()) ?? 0;

  double get saving => bestUk - landedCost;

  String money(double value) => '£${value.toStringAsFixed(2)}';

  @override
  void dispose() {
    cigarPriceController.dispose();
    shippingController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGoldSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22D4AF37),
            blurRadius: 20,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IMPORT CALCULATOR',
            style: TextStyle(
              letterSpacing: 1.2,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Estimate landed cost when importing from EU retailers.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: cigarPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'EU cigar price (£)',
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: shippingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Shipping (£)',
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Quantity',
            ),
          ),

          const SizedBox(height: 20),

          const Divider(),

          const SizedBox(height: 14),

          _CalcRow(label: 'Subtotal', value: money(subtotal)),

          const SizedBox(height: 8),

          _CalcRow(label: 'Estimated duty', value: money(duty)),

          const SizedBox(height: 8),

          _CalcRow(label: 'VAT', value: money(vat)),

          const SizedBox(height: 8),

          _CalcRow(
            label: 'Total landed cost',
            value: money(landedCost),
            gold: true,
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.goldTint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGoldSoft),
            ),
            child: Text(
              saving >= 0
                  ? 'Estimated saving vs UK price: ${money(saving)}'
                  : 'Estimated extra cost vs UK price: ${money(saving.abs())}',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;

  const _CalcRow({
    required this.label,
    required this.value,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            color: gold ? AppColors.gold : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}