import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/shipping_label_pdf.dart';
import '../state/merchant_store.dart';
import '../theme/app_theme.dart';

/// 订单发货、完成、打印等操作（列表与详情共用）。
class MerchantOrderActionsBar extends StatelessWidget {
  const MerchantOrderActionsBar({super.key, required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final store = context.read<MerchantStore>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        if (order.status == OrderStatus.toShip)
          FilledButton.icon(
            onPressed: () => store.shipOrder(order),
            icon: const Icon(Icons.local_shipping_outlined, size: 18),
            label: const Text('发货'),
          ),
        if (order.status == OrderStatus.shipped)
          OutlinedButton.icon(
            onPressed: () => store.completeOrder(order),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('确认完成'),
          ),
        if (order.status == OrderStatus.pendingPayment)
          Text(
            '等待买家付款',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceMuted,
                ),
          ),
        if (order.status == OrderStatus.toShip ||
            order.status == OrderStatus.shipped)
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await printElectronicShippingLabel(
                  order: order,
                  branchName: store.branchName(order.branchId),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('打印失败：$e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('电子面单'),
          ),
      ],
    );
  }
}
