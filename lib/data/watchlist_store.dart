import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cigar.dart';

class WatchlistStore {
  static const String _key = 'watchlist_items';
  static final List<Cigar> _items = [];

  static List<Cigar> get items => List.unmodifiable(_items);

  static bool contains(Cigar cigar) {
    return _items.any(
      (item) => item.name == cigar.name && item.brand == cigar.brand,
    );
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedItems = prefs.getStringList(_key) ?? [];

    _items
      ..clear()
      ..addAll(
        savedItems.map((item) => Cigar.fromMap(jsonDecode(item))).toList(),
      );
  }

  static Future<void> toggle(Cigar cigar) async {
    if (contains(cigar)) {
      _items.removeWhere(
        (item) => item.name == cigar.name && item.brand == cigar.brand,
      );
    } else {
      _items.add(cigar);
    }

    await _save();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _items.map((cigar) => jsonEncode(cigar.toMap())).toList();
    await prefs.setStringList(_key, encoded);
  }
}

class PriceAlertStore {
  static const String _key = 'price_alerts';

  static Future<void> saveAlert(String cigarName, double price) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = prefs.getStringList(_key) ?? [];

    alerts.add(jsonEncode({
      'cigar': cigarName,
      'target': price,
    }));

    await prefs.setStringList(_key, alerts);
  }
}