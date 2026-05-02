import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/auth_store.dart';
import '../state/merchant_store.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_text.dart';
import 'payment_mock_screen.dart';

class CustomerOrdersScreen extends StatelessWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final store = context.watch<MerchantStore>();
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的订单')),
        body: Center(
          child: Text(
            '登录后可查看订单',
            style: TextStyle(color: AppTheme.onSurfaceMuted.withOpacity(0.9)),
          ),
        ),
      );
    }

    final email = auth.email!;
    final mine = store.catalogOrders
        .where((o) => o.buyerEmail != null && o.buyerEmail == email)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('我的订单')),
      body: mine.isEmpty
          ? Center(
              child: Text(
                '暂无订单',
                style: TextStyle(color: AppTheme.onSurfaceMuted.withOpacity(0.9)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mine.length,
              itemBuilder: (context, i) {
                final o = mine[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                o.id,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.onSurfaceMuted,
                                    ),
                              ),
                            ),
                            _StatusChip(status: o.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(dateFmt.format(o.createdAt),
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        for (final it in o.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text(it.productName)),
                                Text('× ${it.quantity}'),
                              ],
                            ),
                          ),
                        if (o.address.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            o.address,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.onSurfaceMuted,
                                ),
                          ),
                        ],
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Text('合计'),
                            const Spacer(),
                            CurrencyText(
                              o.total,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        if (o.status == OrderStatus.pendingPayment) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        PaymentMockScreen(orderId: o.id),
                                  ),
                                );
                              },
                              child: const Text('去支付'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.label,
        style: const TextStyle(fontSize: 12),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
