import 'package:flutter/material.dart';

/// 商家底部 / 侧栏 Tab 切换（供工作台等子页面跳转）。
class MerchantTabScope extends InheritedWidget {
  const MerchantTabScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  final ValueChanged<int> goToTab;

  /// 切换到商家端某个 Tab（工作台 0 · 商品 1 · 订单 2 · 数据 3 · 我的 4）。
  static void goTo(BuildContext context, int index) {
    final w = context.findAncestorWidgetOfExactType<MerchantTabScope>();
    w?.goToTab(index);
  }

  @override
  bool updateShouldNotify(MerchantTabScope oldWidget) => false;
}
