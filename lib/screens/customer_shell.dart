import 'package:flutter/material.dart';

import '../theme/layout_breakpoints.dart';
import 'catalog_screen.dart';
import 'customer_cart_screen.dart';
import 'customer_orders_screen.dart';
import 'customer_profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  static const _titles = ['商城', '购物车', '订单', '我的'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kDesktopNavBreakpoint;
        final extendedRail = constraints.maxWidth >= 1100;

        final stack = IndexedStack(
          index: _index,
          children: const [
            CatalogScreen(),
            CustomerCartScreen(),
            CustomerOrdersScreen(),
            CustomerProfileScreen(),
          ],
        );

        if (!wide) {
          return Scaffold(
            body: stack,
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

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: extendedRail,
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: extendedRail
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                destinations: [
                  for (var i = 0; i < _titles.length; i++)
                    NavigationRailDestination(
                      icon: Icon(_iconOutlined(i)),
                      selectedIcon: Icon(_iconFilled(i)),
                      label: Text(_titles[i]),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: stack),
            ],
          ),
        );
      },
    );
  }

  IconData _iconOutlined(int i) {
    switch (i) {
      case 0:
        return Icons.storefront_outlined;
      case 1:
        return Icons.shopping_cart_outlined;
      case 2:
        return Icons.receipt_long_outlined;
      default:
        return Icons.person_outline;
    }
  }

  IconData _iconFilled(int i) {
    switch (i) {
      case 0:
        return Icons.storefront;
      case 1:
        return Icons.shopping_cart;
      case 2:
        return Icons.receipt_long;
      default:
        return Icons.person;
    }
  }
}
