import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/store_branch.dart';

class _BranchData {
  _BranchData({
    required this.name,
    required this.contactPhone,
    required this.city,
  });

  String name;
  String contactPhone;
  String city;
  final List<Product> products = [];
  final List<ShopOrder> orders = [];
}

/// 本地演示：多门店数据隔离；用户商城固定对应 [catalogBranchId]。
class MerchantStore extends ChangeNotifier {
  MerchantStore() {
    _seed();
  }

  static const String catalogBranchId = 'b1';
  static const _kBranchPref = 'merchant_current_branch_id';

  final Map<String, _BranchData> _branch = {};
  String _currentBranchId = catalogBranchId;

  String get currentBranchId => _currentBranchId;

  List<StoreBranch> get branches =>
      _branch.entries.map((e) => StoreBranch(id: e.key, name: e.value.name, city: e.value.city)).toList();

  /// 当前登录商家操作的门店。
  String get storeName => _branch[_currentBranchId]!.name;

  String get contactPhone => _branch[_currentBranchId]!.contactPhone;

  /// C 端首页标题（对应卖场门店）。
  String get catalogStoreName => _branch[catalogBranchId]!.name;

  Future<void> hydrate() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString(_kBranchPref);
    if (saved != null && _branch.containsKey(saved)) {
      _currentBranchId = saved;
    }
    notifyListeners();
  }

  Future<void> _persistBranch() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBranchPref, _currentBranchId);
  }

  void switchBranch(String branchId) {
    if (!_branch.containsKey(branchId)) return;
    _currentBranchId = branchId;
    notifyListeners();
    _persistBranch();
  }

  String branchName(String branchId) => _branch[branchId]?.name ?? branchId;

  /// 库存预警阈值（≤ 此数量且在架视为预警）。
  static const int lowStockThreshold = 10;

  /// 当前门店：在售且库存偏低的商品（用于工作台预警）。
  List<Product> get lowStockProducts {
    final list = products
        .where((p) => p.onShelf && p.stock > 0 && p.stock <= lowStockThreshold)
        .toList();
    list.sort((a, b) => a.stock.compareTo(b.stock));
    return list;
  }

  List<Product> get products => List.unmodifiable(_branch[_currentBranchId]!.products);

  List<ShopOrder> get orders => List.unmodifiable(_branch[_currentBranchId]!.orders);

  /// 指定门店订单（用于「仅卖场」视图）。
  List<ShopOrder> ordersOnBranch(String branchId) =>
      List.unmodifiable(_branch[branchId]?.orders ?? []);

  /// 全部门店订单合并（按时间倒序）。
  List<ShopOrder> get allOrdersAllBranches {
    final out = <ShopOrder>[];
    for (final b in _branch.values) {
      out.addAll(b.orders);
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  /// 用户订单列表数据源（卖场门店）。
  List<ShopOrder> get catalogOrders => List.unmodifiable(_branch[catalogBranchId]!.orders);

  List<Product> get shelfProducts =>
      _branch[catalogBranchId]!.products.where((p) => p.onShelf).toList(growable: false);

  Product? productForCatalog(String productId) {
    try {
      return _branch[catalogBranchId]!.products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// 扫码入库：匹配当前门店 SKU 或商品 ID。
  String? inboundByScanCode(String raw, int qty) {
    if (qty <= 0) return '请输入大于 0 的数量';
    final code = raw.trim();
    if (code.isEmpty) return '扫码内容为空';
    final list = _branch[_currentBranchId]!.products;
    final upper = code.toUpperCase();
    final i = list.indexWhere(
      (p) => p.id == code || p.sku.toUpperCase() == upper,
    );
    if (i < 0) return '当前门店未找到：$code';
    final p = list[i];
    list[i] = p.copyWith(stock: p.stock + qty);
    notifyListeners();
    return null;
  }

  String? placeCustomerOrder({
    required String buyerEmail,
    required String buyerDisplay,
    required String address,
    required List<CustomerOrderLine> lines,
  }) {
    final catalog = _branch[catalogBranchId]!;
    if (lines.isEmpty) return null;
    for (final line in lines) {
      final i = catalog.products.indexWhere((p) => p.id == line.productId);
      if (i < 0) return null;
      final p = catalog.products[i];
      if (!p.onShelf || p.stock < line.quantity) return null;
    }
    for (final line in lines) {
      final i = catalog.products.indexWhere((p) => p.id == line.productId);
      final p = catalog.products[i];
      catalog.products[i] = p.copyWith(stock: p.stock - line.quantity);
    }
    final items = <OrderItem>[];
    for (final line in lines) {
      final p = catalog.products.firstWhere((x) => x.id == line.productId);
      items.add(
        OrderItem(
          productName: p.name,
          quantity: line.quantity,
          unitPrice: p.price,
          productId: p.id,
        ),
      );
    }
    final id = 'CU-${DateTime.now().millisecondsSinceEpoch}';
    catalog.orders.insert(
      0,
      ShopOrder(
        id: id,
        branchId: catalogBranchId,
        buyer: buyerDisplay,
        buyerEmail: buyerEmail,
        createdAt: DateTime.now(),
        status: OrderStatus.pendingPayment,
        items: items,
        address: address,
      ),
    );
    notifyListeners();
    return id;
  }

  bool mockPaymentSuccess(String orderId) {
    final catalog = _branch[catalogBranchId]!;
    final i = catalog.orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return false;
    final o = catalog.orders[i];
    if (o.status != OrderStatus.pendingPayment) return false;
    o.status = OrderStatus.toShip;
    notifyListeners();
    return true;
  }

  int get pendingShipCount =>
      _branch[_currentBranchId]!.orders.where((o) => o.status == OrderStatus.toShip).length;

  int get todayOrderCount {
    final now = DateTime.now();
    return _branch[_currentBranchId]!.orders.where((o) {
      return o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day;
    }).length;
  }

  double get todayRevenue {
    final now = DateTime.now();
    return _branch[_currentBranchId]!.orders.where((o) {
      return o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day &&
          o.status != OrderStatus.cancelled;
    }).fold(0.0, (sum, o) => sum + o.total);
  }

  List<double> get last7DaysRevenue {
    final now = DateTime.now();
    final days = <double>[];
    final ords = _branch[_currentBranchId]!.orders;
    for (var i = 6; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final sum = ords.where((o) {
        if (o.status == OrderStatus.cancelled) return false;
        final c = o.createdAt;
        return c.year == d.year && c.month == d.month && c.day == d.day;
      }).fold(0.0, (s, o) => s + o.total);
      days.add(sum);
    }
    return days;
  }

  void updateStoreProfile({String? name, String? phone}) {
    final b = _branch[_currentBranchId]!;
    if (name != null) b.name = name;
    if (phone != null) b.contactPhone = phone;
    notifyListeners();
  }

  void addProduct(Product p) {
    _branch[_currentBranchId]!.products.add(p);
    notifyListeners();
  }

  void updateProduct(Product p) {
    final list = _branch[_currentBranchId]!.products;
    final i = list.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      list[i] = p;
      notifyListeners();
    }
  }

  void toggleShelf(Product p) {
    updateProduct(p.copyWith(onShelf: !p.onShelf));
  }

  void shipOrder(ShopOrder o) {
    if (o.status == OrderStatus.toShip) {
      o.status = OrderStatus.shipped;
      notifyListeners();
    }
  }

  void completeOrder(ShopOrder o) {
    if (o.status == OrderStatus.shipped) {
      o.status = OrderStatus.completed;
      notifyListeners();
    }
  }

  void updateOrderMerchantNote(ShopOrder order, String note) {
    order.merchantNote = note;
    notifyListeners();
  }

  void _seed() {
    _branch['b1'] = _BranchData(
      name: '示例精选店',
      contactPhone: '138****0000',
      city: '上海 · 徐汇',
    );
    _branch['b2'] = _BranchData(
      name: '虹桥仓储中心',
      contactPhone: '021-****5678',
      city: '上海 · 闵行',
    );

    _seedProducts('b1', [
      Product(
        id: 'p1',
        name: '纯棉圆领短袖',
        sku: 'TS-001',
        price: 79,
        stock: 120,
        onShelf: true,
        imageEmoji: '👕',
      ),
      Product(
        id: 'p2',
        name: '便携保温水杯',
        sku: 'CUP-02',
        price: 49.9,
        stock: 8,
        onShelf: true,
        imageEmoji: '🥤',
      ),
      Product(
        id: 'p3',
        name: '无线蓝牙耳机',
        sku: 'EAR-77',
        price: 199,
        stock: 0,
        onShelf: false,
        imageEmoji: '🎧',
      ),
    ]);

    _seedProducts('b2', [
      Product(
        id: 'h1',
        name: '纯棉圆领短袖',
        sku: 'TS-001',
        price: 79,
        stock: 200,
        onShelf: true,
        imageEmoji: '👕',
      ),
      Product(
        id: 'h2',
        name: '便携保温水杯',
        sku: 'CUP-02',
        price: 49.9,
        stock: 40,
        onShelf: true,
        imageEmoji: '🥤',
      ),
      Product(
        id: 'h3',
        name: '无线蓝牙耳机',
        sku: 'EAR-77',
        price: 199,
        stock: 15,
        onShelf: false,
        imageEmoji: '🎧',
      ),
    ]);

    final t = DateTime.now();
    _branch['b1']!.orders.addAll([
      ShopOrder(
        id: 'SO-1001',
        branchId: 'b1',
        buyer: '张**',
        createdAt: t.subtract(const Duration(hours: 1)),
        status: OrderStatus.toShip,
        address: '上海市浦东新区 ** 路',
        items: [
          OrderItem(productName: '纯棉圆领短袖', quantity: 2, unitPrice: 79),
        ],
      ),
      ShopOrder(
        id: 'SO-1002',
        branchId: 'b1',
        buyer: '李**',
        createdAt: t.subtract(const Duration(minutes: 20)),
        status: OrderStatus.pendingPayment,
        address: '杭州市西湖区 ** 号',
        items: [
          OrderItem(productName: '便携保温水杯', quantity: 1, unitPrice: 49.9),
        ],
      ),
      ShopOrder(
        id: 'SO-0999',
        branchId: 'b1',
        buyer: '王**',
        createdAt: t.subtract(const Duration(days: 1)),
        status: OrderStatus.completed,
        address: '北京市朝阳区 ** 街',
        items: [
          OrderItem(productName: '无线蓝牙耳机', quantity: 1, unitPrice: 199),
        ],
      ),
    ]);

    _branch['b2']!.orders.add(
      ShopOrder(
        id: 'SO-W01',
        branchId: 'b2',
        buyer: '仓配样品',
        createdAt: t.subtract(const Duration(days: 2)),
        status: OrderStatus.completed,
        address: '闵行仓 ** 区',
        items: [
          OrderItem(productName: '纯棉圆领短袖', quantity: 10, unitPrice: 79),
        ],
      ),
    );
  }

  void _seedProducts(String branchId, List<Product> list) {
    _branch[branchId]!.products.addAll(list);
  }
}
