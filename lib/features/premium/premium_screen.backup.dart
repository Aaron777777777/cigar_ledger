import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/purchase_service.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purchaseService = context.watch<PurchaseService>();

    final isLoading = purchaseService.isLoading;
    final isAvailable = purchaseService.isAvailable;
    final isPremium = purchaseService.isPremium;
    final hasProProduct = purchaseService.proProduct != null;

    String buttonText;
    VoidCallback? onPressed;

    if (isLoading) {
      buttonText = 'Loading...';
      onPressed = null;
    } else if (isPremium) {
      buttonText = 'Pro unlocked';
      onPressed = null;
    } else if (!isAvailable) {
      buttonText = 'Billing unavailable';
      onPressed = null;
    } else if (!hasProProduct) {
      buttonText = 'Pro unlock unavailable';
      onPressed = null;
    } else {
      buttonText = 'Unlock Pro';
      onPressed = purchaseService.buyProUnlock;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.4),
              ),
              color: const Color(0xFF121212),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unlock full UK vs EU comparison',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'See exact EU prices, landed import cost, and real savings across the catalogue.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'WHAT PRO UNLOCKS',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _feature(
            icon: Icons.compare_arrows_rounded,
            title: 'Exact UK vs EU comparison',
            text: 'See the actual imported price, not just a hint that import might be cheaper.',
          ),
          _feature(
            icon: Icons.savings_outlined,
            title: 'Real landed savings',
            text: 'Unlock duty, VAT, each savings, and full box-value views before you buy.',
          ),
          _feature(
            icon: Icons.local_fire_department_outlined,
            title: 'Full deal rankings',
            text: 'See the strongest box and single opportunities across the catalogue.',
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF121212),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchaseService.proPriceLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Annual subscription unlocks the full comparison experience inside Cigar Ledger.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              disabledBackgroundColor:
                  const Color(0xFFD4AF37).withOpacity(0.4),
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(height: 26),
          if (purchaseService.hasAnySupportProducts) ...[
            const Text(
              'OPTIONAL SUPPORT',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            _supportTile(
              title: 'Support the app',
              subtitle: 'A simple thank-you if the app has helped you save money.',
              price: purchaseService.supportSmallPriceLabel,
              onTap: purchaseService.buySupportSmall,
            ),
            _supportTile(
              title: 'Support development',
              subtitle: 'Help fund more cigar coverage, maintenance, and polish.',
              price: purchaseService.supportMediumPriceLabel,
              onTap: purchaseService.buySupportMedium,
            ),
            _supportTile(
              title: 'Founding supporter',
              subtitle: 'For people who want to back the project in a bigger way.',
              price: purchaseService.supportLargePriceLabel,
              onTap: purchaseService.buySupportLarge,
            ),
          ],
          const SizedBox(height: 14),
          if (!isLoading && !isPremium && isAvailable && hasProProduct)
            const Text(
              'Annual subscription and optional support purchases are handled by the store.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  static Widget _feature({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF121212),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37).withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _supportTile({
    required String title,
    required String subtitle,
    required String price,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF121212),
        border: Border.all(
          color: const Color(0x33D4AF37),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
        ),
        trailing: Text(
          price,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}