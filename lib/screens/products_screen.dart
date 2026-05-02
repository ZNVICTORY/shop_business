import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/merchant_store.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_text.dart';
import 'scan_inbound_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filtered(MerchantStore store) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return store.products.toList();
    return store.products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.sku.toLowerCase().contains(q) ||
              p.id.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MerchantStore>();
    final theme = Theme.of(context);
    final list = _filtered(store);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '搜索名称、SKU、编码',
            border: InputBorder.none,
            isDense: true,
          ),
          style: theme.textTheme.titleMedium,
          onChanged: (_) => setState(() {}),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('添加商品'),
      ),
      body: store.products.isEmpty
          ? Center(
              child: Text(
                '暂无商品，点击右下角添加',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            )
          : list.isEmpty
              ? Center(
                  child: Text(
                    '没有匹配「${_searchController.text}」的商品',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = list[i];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openEditor(context, p),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _EmojiAvatar(emoji: p.imageEmoji),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            style: theme.textTheme.titleSmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        _ShelfChip(onShelf: p.onShelf),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'SKU ${p.sku} · 库存 ${p.stock}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.onSurfaceMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    CurrencyText(
                                      p.price,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: p.onShelf ? '下架' : '上架',
                                onPressed: () => store.toggleShelf(p),
                                icon: Icon(
                                  p.onShelf
                                      ? Icons.toggle_on
                                      : Icons.toggle_off_outlined,
                                  color: p.onShelf
                                      ? theme.colorScheme.primary
                                      : AppTheme.onSurfaceMuted,
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

  Future<void> _openEditor(BuildContext context, Product? existing) async {
    final store = context.read<MerchantStore>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toString() : '',
    );
    final stockCtrl = TextEditingController(
      text: existing != null ? existing.stock.toString() : '',
    );
    final emojiCtrl = TextEditingController(text: existing?.imageEmoji ?? '📦');

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
            top: 8,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existing == null ? '新建商品' : '编辑商品',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '商品名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: skuCtrl,
                  decoration: const InputDecoration(
                    labelText: 'SKU',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: '价格',
                          prefixText: '¥ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: '库存',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emojiCtrl,
                  decoration: const InputDecoration(
                    labelText: '列表图标（Emoji）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final sku = skuCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.trim());
                    final stock = int.tryParse(stockCtrl.text.trim());
                    if (name.isEmpty ||
                        sku.isEmpty ||
                        price == null ||
                        stock == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('请填写完整信息')),
                      );
                      return;
                    }
                    if (existing == null) {
                      store.addProduct(
                        Product(
                          id: 'p-${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          sku: sku,
                          price: price,
                          stock: stock,
                          onShelf: true,
                          imageEmoji: emojiCtrl.text.trim().isEmpty
                              ? '📦'
                              : emojiCtrl.text.trim(),
                        ),
                      );
                    } else {
                      store.updateProduct(
                        existing.copyWith(
                          name: name,
                          sku: sku,
                          price: price,
                          stock: stock,
                          imageEmoji: emojiCtrl.text.trim().isEmpty
                              ? existing.imageEmoji
                              : emojiCtrl.text.trim(),
                        ),
                      );
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: Text(existing == null ? '保存并上架' : '保存修改'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存')),
      );
    }
  }
}

class _EmojiAvatar extends StatelessWidget {
  const _EmojiAvatar({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 26)),
    );
  }
}

class _ShelfChip extends StatelessWidget {
  const _ShelfChip({required this.onShelf});

  final bool onShelf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: onShelf
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        onShelf ? '在售' : '已下架',
        style: theme.textTheme.labelSmall?.copyWith(
          color: onShelf
              ? theme.colorScheme.onPrimaryContainer
              : AppTheme.onSurfaceMuted,
        ),
      ),
    );
  }
}
