import 'package:flutter/material.dart';
import 'package:tindahance/screens/dashboard_screen.dart';
import 'package:tindahance/screens/make_sale_screen.dart';
import 'package:tindahance/screens/products_screen.dart';
import 'package:tindahance/screens/credit_screen.dart';
import 'package:tindahance/screens/transaction_history_screen.dart';
import 'package:tindahance/screens/reports_screen.dart';
import 'package:tindahance/screens/settings_screen.dart';
import 'package:tindahance/widgets/app_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
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
      TransactionHistoryScreen(),
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
      drawer: AppDrawer(
        onSelectItem: _onSelectItem,
        selectedIndex: _selectedIndex,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }
}
