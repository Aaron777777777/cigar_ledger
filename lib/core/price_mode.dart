import 'package:flutter/material.dart';

class PriceMode extends ChangeNotifier {
  bool showBoxPrice = false;

  void toggle() {
    showBoxPrice = !showBoxPrice;
    notifyListeners();
  }
}

final PriceMode priceMode = PriceMode();
