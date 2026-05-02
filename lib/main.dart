import 'package:flutter/material.dart';
import 'package:flutter_shop/app.dart';
import 'package:flutter_shop/state/auth_store.dart';
import 'package:flutter_shop/state/merchant_store.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  final auth = AuthStore();
  await auth.load();
  final merchant = MerchantStore();
  await merchant.hydrate();
  runApp(ShopApp(auth: auth, merchant: merchant));
}
