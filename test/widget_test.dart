import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_shop/app.dart';
import 'package:flutter_shop/state/auth_store.dart';
import 'package:flutter_shop/state/merchant_store.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('商城首页展示店铺名称', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('zh_CN');
    final auth = AuthStore();
    await auth.load();
    final merchant = MerchantStore();
    await merchant.hydrate();
    await tester.pumpWidget(ShopApp(auth: auth, merchant: merchant));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('示例精选店'), findsOneWidget);
    expect(find.text('商城'), findsOneWidget);
  });
}
