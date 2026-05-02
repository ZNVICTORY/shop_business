import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../merchant_tab_scope.dart';
import '../state/merchant_store.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_text.dart';
import 'scan_inbound_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MerchantStore>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.storeName, style: theme.textTheme.titleMedium),
            Text(
              '商家工作台',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '扫码入库',
            icon: const Icon(Icons.qr_code_scanner_outlined),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ScanInboundScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: '切换门店',
            icon: const Icon(Icons.store_mall_directory_outlined),
            onSelected: store.switchBranch,
            itemBuilder: (context) => [
              for (final b in store.branches)
                CheckedPopupMenuItem<String>(
                  value: b.id,
                  checked: b.id == store.currentBranchId,
                  child: Text('${b.name} · ${b.city}'),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('今日概览', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final cross = w >= 520 ? 4 : 2;
              return GridView.count(
                crossAxisCount: cross,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: cross == 4 ? 1.45 : 1.22,
                children: [
                  _KpiCard(
                    icon: Icons.payments_outlined,
                    label: '今日成交额',
                    child: CurrencyText(
                      store.todayRevenue,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _KpiCard(
                    icon: Icons.receipt_long_outlined,
                    label: '今日订单',
                    child: Text(
                      '${store.todayOrderCount}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _KpiCard(
                    icon: Icons.local_shipping_outlined,
                    label: '待发货',
                    child: Text(
                      '${store.pendingShipCount}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: store.pendingShipCount > 0
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ),
                  ),
                  _KpiCard(
                    icon: Icons.inventory_2_outlined,
                    label: '在售 SKU',
                    child: Text(
                      '${store.products.where((p) => p.onShelf).length}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (store.lowStockProducts.isNotEmpty) ...[
            Text('库存预警', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '以下 SKU 库存 ≤ ${MerchantStore.lowStockThreshold}，建议补货或入库',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (var i = 0;
                      i < store.lowStockProducts.length && i < 5;
                      i++)
                    ListTile(
                      dense: true,
                      leading: Text(
                        store.lowStockProducts[i].imageEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(store.lowStockProducts[i].name),
                      subtitle: Text('SKU ${store.lowStockProducts[i].sku}'),
                      trailing: Text(
                        '余 ${store.lowStockProducts[i].stock}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  if (store.lowStockProducts.length > 5)
                    ListTile(
                      dense: true,
                      title: Text(
                        '还有 ${store.lowStockProducts.length - 5} 个…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceMuted,
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('前往商品管理'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => MerchantTabScope.goTo(context, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text('快捷入口', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _QuickTile(
                  icon: Icons.add_box_outlined,
                  title: '发布商品',
                  subtitle: '填写名称、价格与库存',
                  onTap: () => _showSnack(context, '请在「商品」页点击右下角添加'),
                ),
                const Divider(height: 1),
                _QuickTile(
                  icon: Icons.assignment_turned_in_outlined,
                  title: '处理待发货',
                  subtitle: '${store.pendingShipCount} 笔订单等待发货',
                  onTap: () => _showSnack(context, '切换到「订单」页签处理'),
                ),
                const Divider(height: 1),
                _QuickTile(
                  icon: Icons.qr_code_scanner_outlined,
                  title: '扫码入库',
                  subtitle: '扫描条码增加当前门店库存',
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const ScanInboundScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(height: 10),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: DefaultTextStyle.merge(
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
