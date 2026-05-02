import 'package:flutter/material.dart';

import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import 'profile_screen.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key});

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int _index = 0;

  static const _titles = [
    '工作台',
    '商品',
    '订单',
    '数据',
    '我的',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          ProductsScreen(),
          OrdersScreen(),
          AnalyticsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (var i = 0; i < _titles.length; i++)
            NavigationDestination(
              icon: Icon(_iconOutlined(i)),
              selectedIcon: Icon(_iconFilled(i)),
              label: _titles[i],
            ),
        ],
      ),
    );
  }

  IconData _iconOutlined(int i) {
    switch (i) {
      case 0:
        return Icons.dashboard_outlined;
      case 1:
        return Icons.inventory_2_outlined;
      case 2:
        return Icons.receipt_long_outlined;
      case 3:
        return Icons.insights_outlined;
      default:
        return Icons.person_outline;
    }
  }

  IconData _iconFilled(int i) {
    switch (i) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.inventory_2;
      case 2:
        return Icons.receipt_long;
      case 3:
        return Icons.insights;
      default:
        return Icons.person;
    }
  }
}
