import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/price_mode.dart';
import '../../data/deal_engine.dart';
import '../../data/sample_cigars.dart';
import '../../models/cigar.dart';
import '../../services/purchase_service.dart';
import '../../widgets/cigar_search_card.dart';
import '../cigar_detail/cigar_detail_screen.dart';

class TopDealsScreen extends StatefulWidget {
  const TopDealsScreen({super.key});

  @override
  State<TopDealsScreen> createState() => _TopDealsScreenState();
}

class _TopDealsScreenState extends State<TopDealsScreen> {
  List<Cigar> cigars = [];
  bool loading = true;
  String? loadError;

  final PageController _recentlyAddedController =
      PageController(viewportFraction: 0.42);

  int _recentlyAddedPage = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _recentlyAddedController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final data = await loadCigars();
      setState(() {
        cigars = _dedupeCigars(data);
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

  List<Cigar> _dedupeCigars(List<Cigar> input) {
    final seen = <String>{};
    final unique = <Cigar>[];

    for (final cigar in input) {
      final key = _cigarKey(cigar);
      if (seen.add(key)) {
        unique.add(cigar);
      }
    }

    return unique;
  }

  String _cigarKey(Cigar cigar) {
    return '${cigar.brand.trim().toLowerCase()}|${cigar.name.trim().toLowerCase()}';
  }

  String _dealKey(DealResult deal) {
    return '${deal.cigar.brand.trim().toLowerCase()}|${deal.cigar.name.trim().toLowerCase()}';
  }

  List<DealResult> _dedupeDeals(List<DealResult> input) {
    final seen = <String>{};
    final unique = <DealResult>[];

    for (final deal in input) {
      final key = _dealKey(deal);
      if (seen.add(key)) {
        unique.add(deal);
      }
    }

    return unique;
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PurchaseService>().isPremium;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Deals failed to load:\n$loadError',
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

        final deals = _dedupeDeals(
          cigars
              .map(calculateDeal)
              .where((deal) {
                if (showBox) {
                  return deal.ukBestBoxPrice > 0 &&
                      deal.euBestBoxPrice > 0 &&
                      deal.euBestBoxPrice < deal.ukBestBoxPrice;
                }

                return deal.ukBestSinglePrice > 0 &&
                    deal.euBestSinglePrice > 0 &&
                    deal.euBestSinglePrice < deal.ukBestSinglePrice;
              })
              .toList(),
        );

        deals.sort((a, b) {
          final aSaving = showBox ? a.savingPerBox : a.savingPerCigar;
          final bSaving = showBox ? b.savingPerBox : b.savingPerCigar;

          final savingCompare = bSaving.compareTo(aSaving);
          if (savingCompare != 0) return savingCompare;

          return b.dealScore.compareTo(a.dealScore);
        });

        if (deals.isEmpty) {
          return Center(
            child: Text(
              showBox
                  ? 'No box import deals available yet'
                  : 'No single-cigar import deals available yet',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        final heroDeal = deals.first;
        final remainingDeals = deals.skip(1).take(8).toList();

        final recentlyAdded = cigars.length <= 3
            ? cigars.reversed.toList()
            : cigars.reversed.take(3).toList();

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
              const SizedBox(height: 2),
              const Text(
                'RECENTLY ADDED',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4AF37),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 214,
                child: PageView.builder(
                  controller: _recentlyAddedController,
                  padEnds: false,
                  onPageChanged: (index) {
                    setState(() {
                      _recentlyAddedPage = index;
                    });
                  },
                  itemCount: recentlyAdded.length,
                  itemBuilder: (context, index) {
                    final cigar = recentlyAdded[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == recentlyAdded.length - 1 ? 0 : 14,
                      ),
                      child: _RecentlyAddedCard(cigar: cigar),
                    );
                  },
                ),
              ),
              if (recentlyAdded.length > 1) ...[
                const SizedBox(height: 10),
                _PageDots(
                  count: recentlyAdded.length,
                  activeIndex:
                      _recentlyAddedPage.clamp(0, recentlyAdded.length - 1),
                  controller: _recentlyAddedController,
                ),
              ],
              const SizedBox(height: 26),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0x14FFFFFF),
              ),
              const SizedBox(height: 26),
              const Text(
                'THIS WEEK’S BEST DEALS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4AF37),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 14),
              _HeroDealCard(
                deal: heroDeal,
                showBox: showBox,
                isPremium: isPremium,
              ),
              if (remainingDeals.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'More top deals',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ...remainingDeals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final deal = entry.value;

                  return CigarSearchCard(
                    cigar: deal.cigar,
                    rank: index + 2,
                    dealStrength: deal.dealStrength,
                    ukSinglePrice: deal.ukBestSinglePrice,
                    euSinglePrice: deal.euBestSinglePrice,
                    ukBoxPrice: deal.ukBestBoxPrice,
                    euBoxPrice: deal.euBestBoxPrice,
                    savingPerCigar: deal.savingPerCigar,
                    savingPerBox: deal.savingPerBox,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CigarDetailScreen(cigar: deal.cigar),
                        ),
                      );
                    },
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RecentlyAddedCard extends StatelessWidget {
  final Cigar cigar;

  const _RecentlyAddedCard({required this.cigar});

  @override
  Widget build(BuildContext context) {
    final lines = _buildDisplayLines(cigar.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CigarDetailScreen(cigar: cigar),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xF0141416),
                Color(0xEE0E0E10),
                Color(0xF0101012),
              ],
            ),
            border: Border.all(color: const Color(0x22D4AF37)),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          color: const Color(0xFF171719),
                          child: _RecentCigarImage(imageUrl: cigar.imageUrl),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      color: Color(0x161A1A1D),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lines.$1,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        if (lines.$2.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            lines.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: const Color(0xFF2A2411),
                    border: Border.all(color: const Color(0x18D4AF37)),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, String) _buildDisplayLines(String name) {
    final cleaned = name.trim();
    final parts = cleaned.split(RegExp(r'\s+'));

    if (parts.length <= 2) {
      return (cleaned, '');
    }

    if (parts.length == 3) {
      return ('${parts[0]} ${parts[1]}', parts[2]);
    }

    return (
      '${parts[0]} ${parts[1]}',
      parts.skip(2).join(' '),
    );
  }
}

class _RecentCigarImage extends StatelessWidget {
  final String imageUrl;

  const _RecentCigarImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return const Center(
        child: Icon(Icons.smoking_rooms, color: Colors.white54, size: 24),
      );
    }

    final isRemote =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    final imageWidget = isRemote
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
          );

    return Container(
      color: const Color(0xFF171719),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: FractionallySizedBox(
        heightFactor: 0.84,
        child: imageWidget,
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  final PageController controller;

  const _PageDots({
    required this.count,
    required this.activeIndex,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == activeIndex
                      ? const Color(0xFFD4AF37)
                      : const Color(0x33D4AF37),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroDealCard extends StatelessWidget {
  final DealResult deal;
  final bool showBox;
  final bool isPremium;

  const _HeroDealCard({
    required this.deal,
    required this.showBox,
    required this.isPremium,
  });

  String _brandAsset(String brand) {
    final normalised = brand
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(' ', '_')
        .replaceAll('\'', '');
    return 'assets/brands/$normalised.png';
  }

  @override
  Widget build(BuildContext context) {
    final cigar = deal.cigar;

    final ukValue = showBox ? deal.ukBestBoxPrice : deal.ukBestSinglePrice;
    final euValue = showBox ? deal.euBestBoxPrice : deal.euBestSinglePrice;
    final hasValidImport = euValue > 0 && euValue < ukValue;

    final savingText = showBox
        ? deal.savingPerBox.toStringAsFixed(0)
        : deal.savingPerCigar.toStringAsFixed(2);

    final savingsLabel = isPremium
        ? showBox
            ? 'SAVE £$savingText PER BOX'
            : 'SAVE £$savingText PER CIGAR'
        : showBox
            ? 'BIG BOX SAVINGS'
            : 'PRO SAVINGS VIEW';

    final savingsSubLabel = isPremium
        ? 'Top value opportunity'
        : 'Unlock Pro for exact savings';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CigarDetailScreen(cigar: cigar),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showBox ? '#1 BEST BOX DEAL' : '#1 BEST SINGLE DEAL',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroImageFrame(imageUrl: cigar.imageUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeroBrandLogo(
                                assetPath: _brandAsset(cigar.brand),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cigar.name,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.08,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cigar.brand,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasValidImport
                                  ? 'EXCELLENT IMPORT DEAL'
                                  : 'UK CURRENTLY BEST',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasValidImport
                                  ? 'Strong import value'
                                  : 'No import advantage',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0x3AD4AF37),
                              Color(0x22D4AF37),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0x88D4AF37),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              savingsLabel,
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              savingsSubLabel,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetricBox(
                        label: showBox ? 'Best UK box' : 'Best UK',
                        value: '£${ukValue.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isPremium
                          ? _HeroMetricBox(
                              label: showBox ? 'EU landed box' : 'EU landed',
                              value: '£${euValue.toStringAsFixed(2)}',
                              gold: hasValidImport,
                            )
                          : _LockedMetricBox(
                              label: showBox ? 'EU landed box' : 'EU landed',
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroImageFrame extends StatelessWidget {
  final String imageUrl;

  const _HeroImageFrame({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 154,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1FFFFFFF),
            Color(0x0DFFFFFF),
          ],
        ),
        border: Border.all(
          color: const Color(0x22D4AF37),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _HeroCigarImage(imageUrl: imageUrl),
      ),
    );
  }
}

class _HeroBrandLogo extends StatelessWidget {
  final String assetPath;

  const _HeroBrandLogo({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(width: 20, height: 20),
      ),
    );
  }
}

class _HeroCigarImage extends StatelessWidget {
  final String imageUrl;

  const _HeroCigarImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return const _HeroImageFallback();
    }

    final isRemote =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return Container(
      color: const Color(0xFF171719),
      alignment: Alignment.center,
      child: isRemote
          ? Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const _HeroImageFallback(),
            )
          : Image.asset(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const _HeroImageFallback(),
            ),
    );
  }
}

class _HeroImageFallback extends StatelessWidget {
  const _HeroImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.smoking_rooms, color: Colors.white54, size: 28),
    );
  }
}

class _HeroMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;

  const _HeroMetricBox({
    required this.label,
    required this.value,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0x1EFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: gold ? const Color(0xFFD4AF37) : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedMetricBox extends StatelessWidget {
  final String label;

  const _LockedMetricBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0x1EFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 6),
          const Text(
            'Unlock Pro for EU price',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}