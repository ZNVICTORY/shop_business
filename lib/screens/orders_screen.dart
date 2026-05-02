import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/order_export.dart';
import '../state/merchant_store.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_text.dart';
import '../widgets/merchant_order_actions.dart';
import 'merchant_order_detail_screen.dart';

enum _OrderScope {
  /// 当前选中门店
  current,

  /// 仅卖场（用户下单所在门店）
  catalogOnly,

  /// 全部门店合并
  allBranches,
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  _OrderScope _scope = _OrderScope.current;

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
    _searchController.dispose();
    super.dispose();
  }

  List<ShopOrder> _baseOrders(MerchantStore store) {
    switch (_scope) {
      case _OrderScope.current:
        return store.orders;
      case _OrderScope.catalogOnly:
        return store.ordersOnBranch(MerchantStore.catalogBranchId);
      case _OrderScope.allBranches:
        return store.allOrdersAllBranches;
    }
  }

  static bool _orderMatches(ShopOrder o, String q) {
    if (q.isEmpty) return true;
    final s = q.trim().toLowerCase();
    if (o.id.toLowerCase().contains(s)) return true;
    if (o.buyer.toLowerCase().contains(s)) return true;
    if (o.address.toLowerCase().contains(s)) return true;
    if (o.merchantNote.toLowerCase().contains(s)) return true;
    for (final it in o.items) {
      if (it.productName.toLowerCase().contains(s)) return true;
    }
    return false;
  }

  Future<void> _exportVisible(BuildContext context) async {
    final store = context.read<MerchantStore>();
    final filter = _tabs[_tabController.index];
    final base = _baseOrders(store);
    final list = base.where((o) {
      if (filter != null && o.status != filter) return false;
      return _orderMatches(o, _searchController.text);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (list.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前没有可导出的订单')),
      );
      return;
    }
    final csv = ordersToCsv(list, store.branchName);
    await shareOrdersCsv(csv);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('已生成 CSV（${list.length} 条），请在分享面板保存或用 Excel 打开')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MerchantStore>();
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MM-dd HH:mm');
    final q = _searchController.text;
    final base = _baseOrders(store);
    final showChip = _scope == _OrderScope.allBranches ||
        (_scope == _OrderScope.catalogOnly &&
            store.currentBranchId != MerchantStore.catalogBranchId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('订单管理'),
        actions: [
          IconButton(
            tooltip: '导出当前列表为 CSV（Excel）',
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () => _exportVisible(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(152),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '搜索订单、买家、地址、备注、商品',
                    prefixIcon: const Icon(Icons.search, size: 22),
                    border: const OutlineInputBorder(),
                    suffixIcon: q.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<_OrderScope>(
                      segments: const [
                        ButtonSegment(
                          value: _OrderScope.current,
                          label: Text('本店'),
                          tooltip: '当前门店订单',
                        ),
                        ButtonSegment(
                          value: _OrderScope.catalogOnly,
                          label: Text('卖场'),
                          tooltip: '用户下单门店（卖场）',
                        ),
                        ButtonSegment(
                          value: _OrderScope.allBranches,
                          label: Text('全部门店'),
                          tooltip: '合并所有门店',
                        ),
                      ],
                      selected: {_scope},
                      onSelectionChanged: (s) {
                        setState(() => _scope = s.first);
                      },
                      showSelectedIcon: false,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [for (final t in _tabs) Tab(text: _tabLabel(t))],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final filter in _tabs)
            _OrderListView(
              orders: base.where((o) {
                if (filter != null && o.status != filter) return false;
                return _orderMatches(o, q);
              }).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
              dateFmt: dateFmt,
              theme: theme,
              showBranchChip: showChip,
              branchName: store.branchName,
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
    this.showBranchChip = false,
    required this.branchName,
  });

  final List<ShopOrder> orders;
  final DateFormat dateFmt;
  final ThemeData theme;
  final bool showBranchChip;
  final String Function(String branchId) branchName;

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
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => MerchantOrderDetailScreen(order: o),
                ),
              );
            },
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
                      if (o.merchantNote.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.sticky_note_2_outlined,
                            size: 18,
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      _StatusBadge(status: o.status),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppTheme.onSurfaceMuted,
                      ),
                    ],
                  ),
                  if (showBranchChip) ...[
                    const SizedBox(height: 6),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(branchName(o.branchId)),
                      padding: EdgeInsets.zero,
                      labelStyle: theme.textTheme.labelSmall,
                    ),
                  ],
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
                  MerchantOrderActionsBar(order: o),
                ],
              ),
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
