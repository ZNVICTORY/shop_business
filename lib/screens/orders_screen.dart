import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../state/merchant_store.dart';
import '../services/shipping_label_pdf.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_text.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = <OrderStatus?>[
    null,
    OrderStatus.pendingPayment,
    OrderStatus.toShip,
    OrderStatus.shipped,
    OrderStatus.completed,
  ];

  static String _tabLabel(OrderStatus? s) {
    if (s == null) return '全部';
    return s.label;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MerchantStore>();
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('订单管理'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [for (final t in _tabs) Tab(text: _tabLabel(t))],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final filter in _tabs)
            _OrderListView(
              orders: store.orders.where((o) {
                if (filter == null) return true;
                return o.status == filter;
              }).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
              dateFmt: dateFmt,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _OrderListView extends StatelessWidget {
  const _OrderListView({
    required this.orders,
    required this.dateFmt,
    required this.theme,
  });

  final List<ShopOrder> orders;
  final DateFormat dateFmt;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          '暂无订单',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.onSurfaceMuted,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final o = orders[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        o.id,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    _StatusBadge(status: o.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${o.buyer} · ${dateFmt.format(o.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                  ),
                ),
                if (o.address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    o.address,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const Divider(height: 20),
                ...o.items.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(line.productName)),
                        Text('×${line.quantity}'),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 88,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: CurrencyText(line.lineTotal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Spacer(),
                    Text(
                      '合计 ',
                      style: theme.textTheme.bodySmall,
                    ),
                    CurrencyText(
                      o.total,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _OrderActions(order: o),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final store = context.read<MerchantStore>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
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
