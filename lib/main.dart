import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/purchase_service.dart';
import 'services/watchlist_service.dart';

import 'core/theme/app_theme.dart';
import 'core/price_mode.dart';
import 'features/search/search_screen.dart';
import 'features/premium/premium_screen.dart';
import 'features/deals/top_deals_screen.dart';
import 'features/watchlist/watchlist_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final purchaseService = PurchaseService();
  await purchaseService.init();

  final watchlistService = WatchlistService();
  await watchlistService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: purchaseService),
        ChangeNotifierProvider.value(value: watchlistService),
      ],
      child: const CigarLedgerApp(),
    ),
  );
}

const String _herfStationPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.vantalabs.herf_station';

Future<void> _openHerfStation() async {
  final appUri = Uri.parse('herfstation://open');
  final storeUri = Uri.parse(_herfStationPlayStoreUrl);

  try {
    final opened = await launchUrl(
      appUri,
      mode: LaunchMode.externalNonBrowserApplication,
    );
    if (opened) return;
  } catch (_) {}

  await launchUrl(
    storeUri,
    mode: LaunchMode.externalApplication,
  );
}

class CigarLedgerApp extends StatelessWidget {
  const CigarLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cigar Ledger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const SearchScreen(),
      Column(
        children: [
          Expanded(child: const TopDealsScreen()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: _openHerfStation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x33D4AF37)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smoke it with others?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Join a live lounge on Herf Station.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Open Herf Station →',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      const WatchlistScreen(),
      const PremiumScreen(),
    ];

    final titles = [
      'CIGAR LEDGER',
      'TOP DEALS',
      'WATCHLIST',
      'PRO',
    ];

    return AnimatedBuilder(
      animation: priceMode,
      builder: (context, _) {
        final isDealsTab = currentIndex == 1;
        final showPriceToggle = currentIndex != 3;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titles[currentIndex],
                  style: const TextStyle(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                if (isDealsTab) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x22D4AF37),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0x33D4AF37),
                      ),
                    ),
                    child: const Text(
                      'THIS WEEK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            centerTitle: true,
            actions: showPriceToggle
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          priceMode.toggle();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: priceMode.showBoxPrice
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFD4AF37),
                                      Color(0xFFB8942F),
                                    ],
                                  )
                                : null,
                            color: priceMode.showBoxPrice
                                ? null
                                : const Color(0xFF1A1A1A),
                            border: Border.all(
                              color: const Color(0x33D4AF37),
                            ),
                          ),
                          child: Text(
                            priceMode.showBoxPrice ? 'BOX' : 'EACH',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: priceMode.showBoxPrice
                                  ? const Color(0xFF111111)
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]
                : [],
          ),
          body: screens[currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_fire_department),
                label: 'Deals',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                label: 'Watchlist',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.workspace_premium_outlined),
                label: 'Pro',
              ),
            ],
          ),
        );
      },
    );
  }
}