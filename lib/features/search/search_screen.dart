import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/price_mode.dart';
import '../../data/deal_engine.dart';
import '../../data/sample_cigars.dart';
import '../../models/cigar.dart';
import '../../services/purchase_service.dart';
import '../../widgets/cigar_search_card.dart';
import '../../widgets/deal_badge.dart';
import '../../widgets/filter_chip.dart';
import '../cigar_detail/cigar_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Cigar> cigars = [];
  bool loading = true;
  String? loadError;

  String query = '';
  String selectedFilter = 'All';
  String selectedBrand = 'All Brands';

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

  List<DealResult> get biggestDeals {
    final results = DealEngine.biggestSavings(cigars);
    return results.take(3).toList();
  }

  List<String> get brandFilters {
    final brands = cigars
        .map((c) => c.brand.trim())
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['All Brands', ...brands];
  }

  String _cigarKey(Cigar cigar) {
    return '${cigar.brand.trim().toLowerCase()}|${cigar.name.trim().toLowerCase()}';
  }

  List<Cigar> _dedupeCigars(List<Cigar> source) {
    final seen = <String>{};
    final unique = <Cigar>[];

    for (final cigar in source) {
      final key = _cigarKey(cigar);
      if (seen.add(key)) {
        unique.add(cigar);
      }
    }

    return unique;
  }

  List<Cigar> _dealsFirstOrder(List<Cigar> source) {
    final deals = DealEngine.biggestSavings(source);
    final dealKeys = deals.map((d) => _cigarKey(d.cigar)).toSet();

    final dealCigars = _dedupeCigars(deals.map((d) => d.cigar).toList());
    final remaining = source.where((c) => !dealKeys.contains(_cigarKey(c))).toList();

    return [...dealCigars, ...remaining];
  }

  List<Cigar> get filteredCigars {
    List<Cigar> list = [...cigars];

    final search = query.toLowerCase().trim();

    if (search.isNotEmpty) {
      final searchTerms = search
          .split(RegExp(r'\s+'))
          .where((term) => term.isNotEmpty)
          .toList();

      list = list.where((cigar) {
        final searchableText = '${cigar.name} ${cigar.brand}'.toLowerCase();

        return searchTerms.every(
          (term) => searchableText.contains(term),
        );
      }).toList();
    }

    switch (selectedFilter) {
      case 'Cuban':
        list = list
            .where((cigar) => cigar.country.toLowerCase() == 'cuba')
            .toList();
        break;

      case 'New World':
        list = list
            .where((cigar) => cigar.country.toLowerCase() != 'cuba')
            .toList();
        break;

      case 'Best Savings':
        final deals = DealEngine.biggestSavings(list);
        list = _dedupeCigars(deals.map((e) => e.cigar).toList());
        break;
    }

    if (selectedBrand != 'All Brands') {
      list = list
          .where((cigar) =>
              cigar.brand.toLowerCase() == selectedBrand.toLowerCase())
          .toList();
    }

    if (selectedFilter != 'Best Savings') {
      list = _dealsFirstOrder(list);
    }

    return _dedupeCigars(list);
  }

  bool _hasCurrentModeComparison(Cigar cigar, {required bool showBox}) {
    final deal = calculateDeal(cigar);
    final hasUkPrice = showBox
        ? deal.ukBestBoxPrice > 0
        : deal.ukBestSinglePrice > 0;
    final hasEuPrice = showBox
        ? deal.euBestBoxPrice > 0
        : deal.euBestSinglePrice > 0;

    return hasUkPrice && hasEuPrice;
  }

  DealResult? _featuredDealForMode({required bool showBox}) {
    final seen = <String>{};

    for (final deal in DealEngine.biggestSavings(cigars)) {
      final key = _cigarKey(deal.cigar);
      if (!seen.add(key)) continue;

      final hasUkPrice = showBox
          ? deal.ukBestBoxPrice > 0
          : deal.ukBestSinglePrice > 0;
      final hasEuPrice = showBox
          ? deal.euBestBoxPrice > 0
          : deal.euBestSinglePrice > 0;

      if (hasUkPrice && hasEuPrice) {
        return deal;
      }
    }

    return null;
  }

  void _showBrandSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: brandFilters.map((brand) {
                return LedgerFilterChip(
                  label: brand,
                  isSelected: selectedBrand == brand,
                  onTap: () {
                    setState(() {
                      selectedBrand = brand;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0B0B),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (loadError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0B0B),
        body: Center(
          child: Text(loadError!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final isPremium = context.watch<PurchaseService>().isPremium;

    return AnimatedBuilder(
      animation: priceMode,
      builder: (context, _) {
        final showBox = priceMode.showBoxPrice;
        final featuredDeal = _featuredDealForMode(showBox: showBox);
        final featuredKey =
            featuredDeal == null ? null : _cigarKey(featuredDeal.cigar);

        final visibleCigars = _dedupeCigars(
          filteredCigars
              .where((cigar) => _hasCurrentModeComparison(cigar, showBox: showBox))
              .where((cigar) =>
                  featuredKey == null || _cigarKey(cigar) != featuredKey)
              .toList(),
        );

        return Scaffold(
          backgroundColor: const Color(0xFF0B0B0B),
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              children: [
                if (featuredDeal != null)
                  _SearchHeroCard(
                    cigar: featuredDeal.cigar,
                    ukSinglePrice: featuredDeal.ukBestSinglePrice,
                    euSinglePrice: featuredDeal.euBestSinglePrice,
                    ukBoxPrice: featuredDeal.ukBestBoxPrice,
                    euBoxPrice: featuredDeal.euBestBoxPrice,
                    savingPerCigar: featuredDeal.savingPerCigar,
                    savingPerBox: featuredDeal.savingPerBox,
                    decisionLabel: featuredDeal.decisionLabel,
                    dealStrength: featuredDeal.dealStrength,
                    isPremium: isPremium,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CigarDetailScreen(cigar: featuredDeal.cigar),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0x1FFFFFFF),
                        Color(0x0DFFFFFF),
                      ],
                    ),
                    border: Border.all(color: const Color(0x22D4AF37)),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        query = value;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search cigars...',
                      hintStyle: TextStyle(color: Colors.white38),
                      prefixIcon:
                          Icon(Icons.search, color: Color(0xFFD4AF37)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      LedgerFilterChip(
                        label: 'All',
                        isSelected: selectedFilter == 'All',
                        onTap: () {
                          setState(() {
                            selectedFilter = 'All';
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      LedgerFilterChip(
                        label: 'Cuban',
                        isSelected: selectedFilter == 'Cuban',
                        onTap: () {
                          setState(() {
                            selectedFilter = 'Cuban';
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      LedgerFilterChip(
                        label: 'New World',
                        isSelected: selectedFilter == 'New World',
                        onTap: () {
                          setState(() {
                            selectedFilter = 'New World';
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      LedgerFilterChip(
                        label: 'Best Savings',
                        isSelected: selectedFilter == 'Best Savings',
                        onTap: () {
                          setState(() {
                            selectedFilter = 'Best Savings';
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      LedgerFilterChip(
                        label: selectedBrand == 'All Brands'
                            ? 'Brands'
                            : selectedBrand,
                        isSelected: selectedBrand != 'All Brands',
                        onTap: _showBrandSheet,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ALL CIGARS',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                if (visibleCigars.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          showBox
                              ? 'No cigars with full box comparison match this filter yet.'
                              : 'No cigars with full per-cigar comparison match this filter yet.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try another filter or switch price mode to see more complete comparisons.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...visibleCigars.map((cigar) {
                    final deal = calculateDeal(cigar);

                    return CigarSearchCard(
                      cigar: cigar,
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
                            builder: (_) => CigarDetailScreen(cigar: cigar),
                          ),
                        );
                        setState(() {});
                      },
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchHeroCard extends StatelessWidget {
  final Cigar cigar;
  final double ukSinglePrice;
  final double euSinglePrice;
  final double ukBoxPrice;
  final double euBoxPrice;
  final double savingPerCigar;
  final double savingPerBox;
  final String decisionLabel;
  final String dealStrength;
  final bool isPremium;
  final VoidCallback onTap;

  const _SearchHeroCard({
    required this.cigar,
    required this.ukSinglePrice,
    required this.euSinglePrice,
    required this.ukBoxPrice,
    required this.euBoxPrice,
    required this.savingPerCigar,
    required this.savingPerBox,
    required this.decisionLabel,
    required this.dealStrength,
    required this.isPremium,
    required this.onTap,
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
    final showBox = priceMode.showBoxPrice;

    final ukDisplayValue = showBox ? ukBoxPrice : ukSinglePrice;
    final euDisplayValue = showBox ? euBoxPrice : euSinglePrice;
    final hasValidImport = euDisplayValue > 0 &&
        ukDisplayValue > 0 &&
        euDisplayValue < ukDisplayValue;

    final ukDisplay =
        ukDisplayValue > 0 ? '£${ukDisplayValue.toStringAsFixed(2)}' : '--';

    final euDisplay =
        euDisplayValue > 0 ? '£${euDisplayValue.toStringAsFixed(2)}' : '--';

    final savingsLabel = isPremium
        ? showBox
            ? 'SAVE £${savingPerBox.toStringAsFixed(0)} PER BOX'
            : 'SAVE £${savingPerCigar.toStringAsFixed(2)} PER CIGAR'
        : showBox
            ? 'BIG BOX SAVINGS'
            : 'PRO SAVINGS VIEW';

    final savingsSubLabel = isPremium
        ? showBox
            ? '£${(cigar.boxQuantity > 0 ? savingPerBox / cigar.boxQuantity : 0).toStringAsFixed(2)} per cigar'
            : decisionLabel
        : 'Unlock Pro for exact savings';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: onTap,
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
            border: Border.all(
              color: const Color(0x26D4AF37),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.34),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
              const BoxShadow(
                color: Color(0x10D4AF37),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DealBadge(
                          label: showBox ? 'BEST BOX DEAL' : 'BEST SINGLE DEAL',
                        ),
                        DealBadge(label: dealStrength.toUpperCase()),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'TOP BUY THIS WEEK',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SearchHeroImageFrame(imageUrl: cigar.imageUrl),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SearchHeroBrandLogo(
                                    assetPath: _brandAsset(cigar.brand),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      cigar.name,
                                      style: const TextStyle(
                                        fontSize: 21,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPremium
                                      ? decisionLabel
                                      : hasValidImport
                                          ? 'Import may be cheaper'
                                          : 'UK currently looks best',
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPremium
                                      ? hasValidImport
                                          ? 'Strong import value'
                                          : 'No import advantage right now'
                                      : 'Unlock Pro for exact EU landed cost',
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
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14D4AF37),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  savingsLabel,
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontSize: 24,
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
                          child: _SearchHeroMetricBox(
                            label: showBox ? 'Best UK box' : 'Best UK',
                            value: ukDisplay,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: isPremium
                              ? _SearchHeroMetricBox(
                                  label:
                                      showBox ? 'EU landed box' : 'EU landed',
                                  value: euDisplay,
                                  gold: hasValidImport,
                                )
                              : _LockedHeroMetricBox(
                                  label:
                                      showBox ? 'EU landed box' : 'EU landed',
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'View best opportunity',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 15,
                          color: Color(0xFFD4AF37),
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
    );
  }
}

class _SearchHeroImageFrame extends StatelessWidget {
  final String imageUrl;

  const _SearchHeroImageFrame({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 176,
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
        child: _SearchHeroCigarImage(imageUrl: imageUrl),
      ),
    );
  }
}

class _SearchHeroBrandLogo extends StatelessWidget {
  final String assetPath;

  const _SearchHeroBrandLogo({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(width: 22, height: 22),
      ),
    );
  }
}

class _SearchHeroCigarImage extends StatelessWidget {
  final String imageUrl;

  const _SearchHeroCigarImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return const _SearchHeroImageFallback();
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
              errorBuilder: (_, __, ___) => const _SearchHeroImageFallback(),
            )
          : Image.asset(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const _SearchHeroImageFallback(),
            ),
    );
  }
}

class _SearchHeroImageFallback extends StatelessWidget {
  const _SearchHeroImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.smoking_rooms, color: Colors.white54, size: 28),
    );
  }
}

class _SearchHeroMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;

  const _SearchHeroMetricBox({
    required this.label,
    required this.value,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1EFFFFFF),
            Color(0x12FFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedHeroMetricBox extends StatelessWidget {
  final String label;

  const _LockedHeroMetricBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x1EFFFFFF),
            Color(0x12FFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
            'Unlock Pro for EU price',
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