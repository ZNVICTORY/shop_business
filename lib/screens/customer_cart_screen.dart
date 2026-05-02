import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_store.dart';
import '../state/cart_store.dart';
import '../state/merchant_store.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_text.dart';
import 'checkout_screen.dart';

class CustomerCartScreen extends StatelessWidget {
  const CustomerCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final merchant = context.watch<MerchantStore>();
    final auth = context.watch<AuthStore>();

    final lines = <({String id, String name, double price, int qty})>[];
    double total = 0;
    for (final e in cart.quantities.entries) {
      try {
        final p = merchant.products.firstWhere((x) => x.id == e.key);
        final sub = p.price * e.value;
        total += sub;
        lines.add((id: p.id, name: p.name, price: p.price, qty: e.value));
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: const Text('购物车')),
      body: lines.isEmpty
          ? Center(
              child: Text(
                '购物车是空的',
                style: TextStyle(color: AppTheme.onSurfaceMuted.withOpacity(0.9)),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final row = lines[i];
                      return Card(
                        child: ListTile(
                          title: Text(row.name),
                          subtitle: CurrencyText(row.price),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  cart.add(row.id, -1);
                                },
                              ),
                              Text('${row.qty}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  final stock = merchant.products
                                      .firstWhere((x) => x.id == row.id)
                                      .stock;
                                  if (row.qty >= stock) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('库存不足')),
                                    );
                                    return;
                                  }
                                  cart.add(row.id, 1);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Material(
                  elevation: 8,
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '合计',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.onSurfaceMuted,
                                    ),
                              ),
                              CurrencyText(
                                total,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () async {
                              if (!auth.isLoggedIn) {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('需要登录'),
                                    content: const Text('结账前请先登录或注册（「我的」页面）。'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('取消'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('去登录'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true && context.mounted) {
                                  // User switches tab manually — CustomerShell has Profile at index 3.
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('请切换到「我的」完成登录')),
                                  );
                                }
                                return;
                              }
                              if (!context.mounted) return;
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutScreen(),
                                ),
                              );
                            },
                            child: const Text('去结账'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
