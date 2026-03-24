import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/price_mode.dart';
import '../../data/deal_engine.dart';
import '../../data/sample_cigars.dart';
import '../../models/cigar.dart';
import '../../services/purchase_service.dart';
import '../../services/watchlist_service.dart';
import '../cigar_detail/cigar_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  List<Cigar> cigars = [];
  bool loading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await loadCigars();
      setState(() {
        cigars = data;
        loading = false;
        loadError = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        loadError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistService>();
    final isPremium = context.watch<PurchaseService>().isPremium;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Watchlist failed to load:\n$loadError',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: priceMode,
      builder: (context, _) {
        final showBox = priceMode.showBoxPrice;

        final savedCigars = cigars.where(watchlist.matches).toList()
          ..sort((a, b) {
            final dealA = calculateDeal(a);
            final dealB = calculateDeal(b);
            final saveA = showBox ? dealA.savingPerBox : dealA.savingPerCigar;
            final saveB = showBox ? dealB.savingPerBox : dealB.savingPerCigar;
            return saveB.compareTo(saveA);
          });

        return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            children: [
              const Text(
                'SAVED CIGARS',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4AF37),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                savedCigars.isEmpty
                    ? 'Nothing saved yet.'
                    : 'Tap the gold heart on a cigar to save it here.',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              if (savedCigars.isEmpty)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xF0141416),
                        Color(0xEE0E0E10),
                      ],
                    ),
                    border: Border.all(color: const Color(0x26D4AF37)),
                  ),
                  child: const Column(
                    children: [
                      SizedBox(height: 10),
                      Icon(
                        Icons.favorite_border,
                        size: 34,
                        color: Color(0x66D4AF37),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Your watchlist is empty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Open any cigar and tap the gold heart to save it here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                )
              else
                ...savedCigars.map((cigar) {
                  final deal = calculateDeal(cigar);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _WatchlistCard(
                      cigar: cigar,
                      deal: deal,
                      showBox: showBox,
                      isPremium: isPremium,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CigarDetailScreen(cigar: cigar),
                          ),
                        );
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      onHeartTap: () async {
                        await context.read<WatchlistService>().remove(cigar);
                      },
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _WatchlistCard extends StatelessWidget {
  final Cigar cigar;
  final DealResult deal;
  final bool showBox;
  final bool isPremium;
  final VoidCallback onTap;
  final VoidCallback onHeartTap;

  const _WatchlistCard({
    required this.cigar,
    required this.deal,
    required this.showBox,
    required this.isPremium,
    required this.onTap,
    required this.onHeartTap,
  });

  @override
  Widget build(BuildContext context) {
    final ukValue = showBox ? deal.ukBestBoxPrice : deal.ukBestSinglePrice;
    final euValue = showBox ? deal.euBestBoxPrice : deal.euBestSinglePrice;
    final savingValue = showBox ? deal.savingPerBox : deal.savingPerCigar;

    final savingsLabel = showBox
        ? 'SAVE £${savingValue.toStringAsFixed(0)} PER BOX'
        : 'SAVE £${savingValue.toStringAsFixed(2)} PER CIGAR';

    final headlineText = isPremium
        ? (savingValue > 0 ? savingsLabel : 'CURRENTLY TRACKED')
        : 'PRO SAVINGS VIEW';

    final subtitleText = isPremium
        ? null
        : 'Unlock Pro to see exact savings';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xF0141416),
                Color(0xEE0E0E10),
                Color(0xF0101012),
              ],
            ),
            border: Border.all(color: const Color(0x26D4AF37)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WatchlistImage(imageUrl: cigar.imageUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              cigar.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: onHeartTap,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1B1B1D),
                                border: Border.all(
                                  color: const Color(0x33D4AF37),
                                ),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Color(0xFFD4AF37),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cigar.brand,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        headlineText,
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitleText != null) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Unlock Pro to see exact savings',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PriceBox(
                              label: showBox ? 'Best UK box' : 'Best UK',
                              value: ukValue > 0
                                  ? '£${ukValue.toStringAsFixed(2)}'
                                  : '--',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: isPremium
                                ? _PriceBox(
                                    label: showBox
                                        ? 'EU landed box'
                                        : 'EU landed',
                                    value: euValue > 0
                                        ? '£${euValue.toStringAsFixed(2)}'
                                        : '--',
                                    gold: euValue > 0 && euValue < ukValue,
                                  )
                                : _LockedPriceBox(
                                    label:
                                        showBox ? 'EU landed box' : 'EU landed',
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchlistImage extends StatelessWidget {
  final String imageUrl;

  const _WatchlistImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isRemote =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return Container(
      width: 92,
      height: 132,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1FFFFFFF),
            Color(0x0DFFFFFF),
          ],
        ),
        border: Border.all(color: const Color(0x22D4AF37)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: const Color(0xFF171719),
          alignment: Alignment.center,
          child: isRemote
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.smoking_rooms,
                    color: Colors.white54,
                    size: 24,
                  ),
                )
              : Image.asset(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.smoking_rooms,
                    color: Colors.white54,
                    size: 24,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;

  const _PriceBox({
    required this.label,
    required this.value,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0x1EFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: gold ? const Color(0xFFD4AF37) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedPriceBox extends StatelessWidget {
  final String label;

  const _LockedPriceBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0x1EFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pro',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}