import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_store.dart';
import '../theme/app_theme.dart';
import 'merchant_shell.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  final _regName = TextEditingController();

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPass.dispose();
    _regEmail.dispose();
    _regPass.dispose();
    _regName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (auth.isLoggedIn) ...[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (auth.displayName != null && auth.displayName!.isNotEmpty)
                        ? auth.displayName![0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(auth.displayName ?? '用户'),
                subtitle: Text(auth.email ?? ''),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout),
              label: const Text('退出登录'),
            ),
          ] else ...[
            Text('登录', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _loginEmail,
              decoration: const InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _loginPass,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final err = await auth.login(
                  email: _loginEmail.text,
                  password: _loginPass.text,
                );
                if (!context.mounted) return;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('登录成功')),
                  );
                }
              },
              child: const Text('登录'),
            ),
            const SizedBox(height: 32),
            Text('注册', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '演示环境使用本地存储单账号，重新注册会覆盖上一账号。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceMuted,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _regEmail,
              decoration: const InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _regName,
              decoration: const InputDecoration(
                labelText: '昵称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _regPass,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                final err = await auth.register(
                  email: _regEmail.text,
                  password: _regPass.text,
                  displayName: _regName.text,
                );
                if (!context.mounted) return;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('注册成功，已自动登录')),
                  );
                }
              },
              child: const Text('注册'),
            ),
          ],
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('商家后台'),
            subtitle: Text(
              '管理商品与订单（演示同一数据源）',
              style: TextStyle(color: AppTheme.onSurfaceMuted.withOpacity(0.9)),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (!auth.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请先登录后再进入商家后台')),
                );
                return;
              }
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const MerchantShell(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
