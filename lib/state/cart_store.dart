import 'package:flutter/foundation.dart';

import '../models/order.dart';

/// 购物车：productId -> 数量。
class CartStore extends ChangeNotifier {
  final Map<String, int> _qty = {};

  Map<String, int> get quantities => Map.unmodifiable(_qty);

  int quantityOf(String productId) => _qty[productId] ?? 0;

  int get totalItems =>
      _qty.values.fold(0, (a, b) => a + b);

  void setQuantity(String productId, int q) {
    if (q <= 0) {
      _qty.remove(productId);
    } else {
      _qty[productId] = q;
    }
    notifyListeners();
  }

  void add(String productId, [int delta = 1]) {
    final next = quantityOf(productId) + delta;
    setQuantity(productId, next);
  }

  void removeLine(String productId) {
    _qty.remove(productId);
    notifyListeners();
  }

  void clear() {
    _qty.clear();
    notifyListeners();
  }

  List<CustomerOrderLine> toOrderLines() {
    final lines = <CustomerOrderLine>[];
    for (final e in _qty.entries) {
      if (e.value > 0) {
        lines.add(CustomerOrderLine(productId: e.key, quantity: e.value));
      }
    }
    return lines;
  }
}
