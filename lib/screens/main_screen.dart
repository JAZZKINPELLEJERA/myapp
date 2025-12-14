
import 'package:flutter/material.dart';
import 'package:myapp/screens/dashboard_screen.dart';
import 'package:myapp/screens/make_sale_screen.dart';
import 'package:myapp/screens/products_screen.dart';
import 'package:myapp/screens/credit_screen.dart';
import 'package:myapp/screens/transaction_history_screen.dart';
import 'package:myapp/screens/reports_screen.dart';
import 'package:myapp/screens/settings_screen.dart';
import 'package:myapp/widgets/app_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  static const List<String> _widgetTitles = <String>[
    'Dashboard',
    'Make a Sale',
    'Products',
    'Credit (Utang)',
    'Transaction History',
    'Reports',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      DashboardScreen(navigateToTab: _onSelectItem),
      MakeSaleScreen(navigateToTab: _onSelectItem),
      const ProductsScreen(),
      const CreditScreen(),
      const TransactionHistoryScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];
  }

  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Close the drawer if it's open
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_widgetTitles[_selectedIndex]),
        backgroundColor: Colors.teal[400],
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(onSelectItem: _onSelectItem),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }
}
