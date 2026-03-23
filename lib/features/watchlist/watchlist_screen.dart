import 'package:flutter/material.dart';
import '../../data/watchlist_store.dart';
import '../../models/cigar.dart';
import '../cigar_detail/cigar_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  @override
  Widget build(BuildContext context) {
    final List<Cigar> cigars = WatchlistStore.items;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B0B0B),
            Color(0xFF0E0E0E),
            Color(0xFF111111),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'WATCHLIST',
            style: TextStyle(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD4AF37),
            ),
          ),
          centerTitle: true,
        ),
        body: cigars.isEmpty
            ? const Center(
                child: Text(
                  'No cigars saved yet',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 16,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cigars.length,
                itemBuilder: (context, index) {
                  final cigar = cigars[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0x22D4AF37),
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        cigar.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        cigar.brand,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFFD4AF37),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CigarDetailScreen(cigar: cigar),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}