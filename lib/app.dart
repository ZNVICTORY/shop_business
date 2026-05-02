import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/customer_shell.dart';
import 'state/auth_store.dart';
import 'state/cart_store.dart';
import 'state/merchant_store.dart';
import 'theme/app_theme.dart';

class ShopApp extends StatelessWidget {
  const ShopApp({
    super.key,
    required this.auth,
    required this.merchant,
  });

  final AuthStore auth;
  final MerchantStore merchant;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MerchantStore>.value(value: merchant),
        ChangeNotifierProvider<AuthStore>.value(value: auth),
        ChangeNotifierProvider(create: (_) => CartStore()),
      ],
      child: MaterialApp(
        title: '示例商城',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const CustomerShell(),
      ),
    );
  }
}
