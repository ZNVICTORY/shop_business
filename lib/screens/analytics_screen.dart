import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/merchant_store.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_text.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MerchantStore>();
    final theme = Theme.of(context);
    final series = store.last7DaysRevenue;
    final maxVal = series.fold<double>(
      1,
      (m, v) => v > m ? v : m,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('经营数据')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('近 7 日成交额（演示数据）', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < series.length; i++)
                      Expanded(
                        child: _Bar(
                          value: series[i],
                          maxVal: maxVal,
                          label: _dayLabel(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('汇总', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('近 7 日总成交额'),
                  trailing: CurrencyText(
                    series.fold(0.0, (a, b) => a + b),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('在售商品数'),
                  trailing: Text(
                    '${store.products.where((p) => p.onShelf).length}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('累计订单（演示）'),
                  trailing: Text(
                    '${store.orders.length}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '连接后端后，可替换为真实 GMV、转化率、客单价等指标。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(int index) {
    final daysAgo = 6 - index;
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    return DateFormat('E', 'zh_CN').format(d);
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.maxVal,
    required this.label,
  });

  final double value;
  final double maxVal;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = maxVal <= 0 ? 0.0 : (value / maxVal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 180 * h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppTheme.primary.withOpacity(0.35),
                      AppTheme.primary.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
