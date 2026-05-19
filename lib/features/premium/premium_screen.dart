import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../services/purchase_service.dart';
import '../../services/app_config_service.dart';

const String _cigarLedgerPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.aaronsapps.cigarledger';

Future<void> _openCigarLedgerReview() async {
  final storeUri = Uri.parse(_cigarLedgerPlayStoreUrl);

  await launchUrl(
    storeUri,
    mode: LaunchMode.externalApplication,
  );
}

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  CigarLedgerAppConfig appConfig = CigarLedgerAppConfig.defaults();

  @override
  void initState() {
    super.initState();

    const AppConfigService().loadCigarLedgerConfig().then((config) {
      if (!mounted) return;
      setState(() {
        appConfig = config;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final purchaseService = context.watch<PurchaseService>();

    final isLoading = purchaseService.isLoading;
    final isAvailable = purchaseService.isAvailable;
    final isPremium = purchaseService.isPremium;
    final hasProProduct = purchaseService.proProduct != null;
    final canBuy = !isLoading && !isPremium && isAvailable && hasProProduct;

    final helperText = isPremium
        ? 'Know instantly if EU is cheaper, landed costs, and full deal rankings are ready.'
        : isLoading
            ? 'Checking Pro access now.'
            : !isAvailable
                ? 'Store connection is unavailable right now.'
                : !hasProProduct
                    ? 'Pro unlock is not available right now.'
                    : '${purchaseService.proPriceLabel} per month. Know instantly if EU is cheaper, landed costs, and full deal rankings.';

    final buttonText = isLoading
        ? 'Loading...'
        : isPremium
            ? 'Pro unlocked'
            : !isAvailable
                ? 'Billing unavailable'
                : !hasProProduct
                    ? 'Pro unlock unavailable'
                    : appConfig.premiumUnlockButtonText;

    final VoidCallback? onPressed = canBuy ? purchaseService.buyProUnlock : null;

    return Scaffold(
      backgroundColor: Colors.black,
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),
            _PremiumHero(appConfig: appConfig),
            const SizedBox(height: 24),
            Text(
              appConfig.premiumSectionTitle,
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            _FeatureCard(
  icon: Icons.compare_arrows_rounded,
  title: appConfig.premiumFeatureOneTitle,
  text: appConfig.premiumFeatureOneText,
),
            _FeatureCard(
  icon: Icons.savings_outlined,
  title: appConfig.premiumFeatureTwoTitle,
  text: appConfig.premiumFeatureTwoText,
),
            _FeatureCard(
  icon: Icons.local_fire_department_outlined,
  title: appConfig.premiumFeatureThreeTitle,
  text: appConfig.premiumFeatureThreeText,
),
            const SizedBox(height: 16),
            _CtaCard(
              appConfig: appConfig,
              isPremium: isPremium,
              isLoading: isLoading,
              canBuy: canBuy,
              helperText: helperText,
              buttonText: buttonText,
              onPressed: onPressed,
            ),
            const SizedBox(height: 26),
            Text(
              appConfig.premiumSupportTitle,
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            _ReviewTile(
              title: appConfig.premiumReviewTitle,
              subtitle:
                  appConfig.premiumReviewSubtitle,
              onTap: _openCigarLedgerReview,
            ),
            if (true) ...[
              const SizedBox(height: 12),
              _SupportTile(
                title: 'Buy me a coffee',
                subtitle:
                    'If Cigar Ledger saved you money, this is a simple way to say thanks.',
                price: purchaseService.supportMediumPriceLabel,
                onTap: purchaseService.buySupportMedium,
              ),
            ],
            const SizedBox(height: 14),
            if (!isLoading && !isPremium && isAvailable && hasProProduct)
              const Text(
                'Monthly subscription and optional support purchases are handled by the store.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  final CigarLedgerAppConfig appConfig;

  const _PremiumHero({required this.appConfig});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xF0141416),
            Color(0xEE0E0E10),
          ],
        ),
        border: Border.all(color: const Color(0x66D4AF37)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appConfig.premiumHeroTitle,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            appConfig.premiumHeroSubtitle,
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaCard extends StatelessWidget {
  final bool isPremium;
  final bool isLoading;
  final bool canBuy;
  final String helperText;
  final String buttonText;
  final VoidCallback? onPressed;
  final CigarLedgerAppConfig appConfig;

  const _CtaCard({
    required this.isPremium,
    required this.isLoading,
    required this.canBuy,
    required this.helperText,
    required this.buttonText,
    required this.onPressed,
    required this.appConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium
              ? AppColors.borderGoldMedium
              : AppColors.borderGoldSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPremium ? 'Pro' : 'Unlock Pro — £3.99/month',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            helperText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (isPremium)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderGoldSoft),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      appConfig.premiumActiveText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: canBuy
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFD4AF37),
                            Color(0xFFB8962E),
                          ],
                        )
                      : null,
                  color: canBuy ? null : const Color(0xFF1A1A1A),
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  border: canBuy
                      ? null
                      : Border.all(color: AppColors.borderGoldSoft),
                ),
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white70),
                          ),
                        )
                      : Text(
                          buttonText,
                          style: TextStyle(
                            color: canBuy ? Colors.black : Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF121212),
        border: Border.all(color: AppColors.borderGoldSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4AF37).withOpacity(0.16),
            ),
            child: Icon(
              icon,
              color: AppColors.gold,
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
                    fontWeight: FontWeight.w800,
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
}

class _ReviewTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReviewTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF121212),
        border: Border.all(color: AppColors.borderGoldSoft),
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
        trailing: const Icon(
          Icons.open_in_new_rounded,
          color: AppColors.gold,
          size: 20,
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onTap;

  const _SupportTile({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF121212),
        border: Border.all(color: AppColors.borderGoldSoft),
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
            color: AppColors.gold,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}