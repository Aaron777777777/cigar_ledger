import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cigar.dart';

class WatchlistService extends ChangeNotifier {
  static const String _prefsKey = 'cigar_ledger_watchlist_v1';

  final Set<String> _savedKeys = <String>{};
  bool _isReady = false;

  bool get isReady => _isReady;
  int get savedCount => _savedKeys.length;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? const <String>[];

    _savedKeys
      ..clear()
      ..addAll(stored);

    _isReady = true;
    notifyListeners();
  }

  String keyFor(Cigar cigar) =>
      '${cigar.brand.trim().toLowerCase()}__${cigar.name.trim().toLowerCase()}';

  bool isSaved(Cigar cigar) => _savedKeys.contains(keyFor(cigar));

  bool matches(Cigar cigar) => isSaved(cigar);

  Future<void> toggle(Cigar cigar) async {
    final key = keyFor(cigar);

    if (_savedKeys.contains(key)) {
      _savedKeys.remove(key);
    } else {
      _savedKeys.add(key);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> remove(Cigar cigar) async {
    _savedKeys.remove(keyFor(cigar));
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    _savedKeys.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _savedKeys.toList()..sort());
  }
}