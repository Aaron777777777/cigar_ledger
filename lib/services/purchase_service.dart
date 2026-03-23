import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService extends ChangeNotifier {
  // Kept existing constant name to avoid breaking callers in the app, but
  // this now points to the active Play subscription product.
  static const String proUnlockProductId = 'cigar_ledger_premium';
  static const String supportSmallProductId = 'support_small';
  static const String supportMediumProductId = 'support_medium';
  static const String supportLargeProductId = 'support_large';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _isPremium = false;
  bool _isLoading = true;
  List<ProductDetails> _products = [];

  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  List<ProductDetails> get products => _products;

  ProductDetails? get proProduct => _productById(proUnlockProductId);
  ProductDetails? get supportSmallProduct => _productById(supportSmallProductId);
  ProductDetails? get supportMediumProduct => _productById(supportMediumProductId);
  ProductDetails? get supportLargeProduct => _productById(supportLargeProductId);

  bool get hasAnySupportProducts =>
      supportSmallProduct != null ||
      supportMediumProduct != null ||
      supportLargeProduct != null;

  String get proPriceLabel => proProduct?.price ?? '£9.99/year';
  String get supportSmallPriceLabel => supportSmallProduct?.price ?? '£2.99';
  String get supportMediumPriceLabel => supportMediumProduct?.price ?? '£4.99';
  String get supportLargePriceLabel => supportLargeProduct?.price ?? '£9.99';

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _isAvailable = await _inAppPurchase.isAvailable();

    if (_isAvailable) {
      _subscription ??= _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          debugPrint('Purchase stream error: $error');
        },
      );

      await loadProducts();
      _isPremium = false;
      await restorePurchases();
    } else {
      _isPremium = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    const ids = <String>{
      proUnlockProductId,
      supportSmallProductId,
      supportMediumProductId,
      supportLargeProductId,
    };

    final response = await _inAppPurchase.queryProductDetails(ids);

    if (response.error != null) {
      debugPrint('Product query error: ${response.error}');
    }

    _products = response.productDetails;
    notifyListeners();
  }

  ProductDetails? _productById(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<void> buyProUnlock() async {
    await _buyProduct(
      productId: proUnlockProductId,
      consumable: false,
      missingLog: 'Premium subscription product not found.',
    );
  }

  Future<void> buySupportSmall() async {
    await _buyProduct(
      productId: supportSmallProductId,
      consumable: true,
      missingLog: 'Support small product not found.',
    );
  }

  Future<void> buySupportMedium() async {
    await _buyProduct(
      productId: supportMediumProductId,
      consumable: true,
      missingLog: 'Support medium product not found.',
    );
  }

  Future<void> buySupportLarge() async {
    await _buyProduct(
      productId: supportLargeProductId,
      consumable: true,
      missingLog: 'Support large product not found.',
    );
  }

  Future<void> _buyProduct({
    required String productId,
    required bool consumable,
    required String missingLog,
  }) async {
    final product = _productById(productId);

    if (product == null) {
      debugPrint(missingLog);
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    if (consumable) {
      await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );
    } else {
      await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    }
  }

  // Kept as aliases so older files do not break if still calling them.
  Future<void> buyPremiumMonthly() async {
    await buyProUnlock();
  }

  Future<void> buyPremiumAnnual() async {
    await buyProUnlock();
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    bool hasActivePremium = _isPremium;

    for (final purchase in purchases) {
      if (purchase.productID == proUnlockProductId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          hasActivePremium = true;
        }
      }

      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
    }

    _isPremium = hasActivePremium;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
