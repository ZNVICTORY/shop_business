import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/merchant_store.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MerchantStore>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('店铺与账号')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.storefront, color: theme.colorScheme.primary),
              ),
              title: Text(store.storeName),
              subtitle: Text('客服电话 ${store.contactPhone}'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editProfile(context),
            ),
          ),
          const SizedBox(height: 16),
          Text('常用', style: theme.textTheme.titleSmall),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('消息通知'),
                  subtitle: Text(
                    '订单与平台公告（演示）',
                    style: TextStyle(color: AppTheme.onSurfaceMuted),
                  ),
                  trailing: Switch.adaptive(
                    value: true,
                    onChanged: (_) {},
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('店铺认证'),
                  subtitle: Text(
                    '未认证 · 去提交资质',
                    style: TextStyle(color: theme.colorScheme.tertiary),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _toast(context, '此处对接资质审核流程'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('帮助与客服'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _toast(context, '可跳转工单或帮助中心'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '当前为本地演示数据；登录、权限与接口可在接入后端时补齐。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final store = context.read<MerchantStore>();
    final nameCtrl = TextEditingController(text: store.storeName);
    final phoneCtrl = TextEditingController(text: store.contactPhone);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('编辑店铺信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '店铺名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '客服电话',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                store.updateStoreProfile(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
