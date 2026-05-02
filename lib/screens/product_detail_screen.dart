import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/cart_store.dart';
import '../state/merchant_store.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_text.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final merchant = context.watch<MerchantStore>();
    final cart = context.watch<CartStore>();
    final p = merchant.productForCatalog(productId);

    if (p == null || !p.onShelf) {
      return Scaffold(
        appBar: AppBar(title: const Text('商品')),
        body: const Center(child: Text('商品不存在或已下架')),
      );
    }

    final qty = cart.quantityOf(p.id);
    final product = p;

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(p.imageEmoji, style: const TextStyle(fontSize: 96)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            p.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          CurrencyText(
            p.price,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'SKU ${p.sku}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceMuted,
                ),
          ),
          Text(
            '库存 ${p.stock} 件',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceMuted,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            '商品说明',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '此为演示数据。接入后端后将展示详情图文与规格选择。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceMuted,
                  height: 1.45,
                ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: product.stock <= 0 || qty <= 0
                    ? null
                    : () => cart.add(product.id, -1),
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$qty',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                onPressed: product.stock <= 0 || qty >= product.stock
                    ? null
                    : () => cart.add(product.id, 1),
                icon: const Icon(Icons.add),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: product.stock <= 0
                    ? null
                    : () {
                        cart.add(product.id, 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已加入购物车')),
                        );
                      },
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('加入购物车'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
