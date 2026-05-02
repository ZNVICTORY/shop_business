enum OrderStatus {
  pendingPayment,
  toShip,
  shipped,
  completed,
  cancelled,
}

/// 用户下单时的行项目（仅含 id 与数量，价格在服务端由商品表带出）。
class CustomerOrderLine {
  const CustomerOrderLine({required this.productId, required this.quantity});
  final String productId;
  final int quantity;
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pendingPayment:
        return '待付款';
      case OrderStatus.toShip:
        return '待发货';
      case OrderStatus.shipped:
        return '已发货';
      case OrderStatus.completed:
        return '已完成';
      case OrderStatus.cancelled:
        return '已取消';
    }
  }
}

class OrderItem {
  OrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.productId,
  });

  final String productName;
  final int quantity;
  final double unitPrice;
  /// 本地演示用于扣库存；历史订单可为 null。
  final String? productId;

  double get lineTotal => quantity * unitPrice;
}

class ShopOrder {
  ShopOrder({
    required this.id,
    required this.branchId,
    required this.buyer,
    required this.createdAt,
    required this.status,
    required this.items,
    this.address = '',
    this.buyerEmail,
    this.merchantNote = '',
  });

  final String id;
  /// 所属门店；用户下单写入 [MerchantStore.catalogBranchId]。
  final String branchId;
  final String buyer;
  /// 用户侧账号，用于「我的订单」筛选；商家端种子订单可为 null。
  final String? buyerEmail;
  final DateTime createdAt;
  OrderStatus status;
  final List<OrderItem> items;
  String address;

  /// 商家备注（本地演示；接后端后同步接口）。
  String merchantNote;

  double get total => items.fold(0, (a, b) => a + b.lineTotal);
}
