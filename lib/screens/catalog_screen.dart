import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/merchant_store.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_text.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MerchantStore>();
    final list = store.shelfProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(store.catalogStoreName),
      ),
      body: list.isEmpty
          ? Center(
              child: Text(
                '暂无在售商品',
                style: TextStyle(color: AppTheme.onSurfaceMuted.withOpacity(0.8)),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final p = list[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProductDetailScreen(productId: p.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                p.imageEmoji,
                                style: const TextStyle(fontSize: 52),
                              ),
                            ),
                          ),
                          Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          CurrencyText(
                            p.price,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '库存 ${p.stock}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.onSurfaceMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
