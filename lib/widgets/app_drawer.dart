import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tindahance/services/auth_service.dart';

class AppDrawer extends StatefulWidget {
  final Function(int) onSelectItem;
  final int selectedIndex;

  const AppDrawer(
      {super.key, required this.onSelectItem, required this.selectedIndex});

  @override
  State<AppDrawer> createState() => AppDrawerState();
}

class AppDrawerState extends State<AppDrawer> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  String? _storeName;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _fetchStoreName();
    }
  }

  Future<void> _fetchStoreName() async {
    if (_user == null || !mounted) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_user.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _storeName = userDoc.data()?['storeName'];
        });
      }
    } catch (e) {
      // Handle error appropriately, e.g., log it
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(_user),
          Expanded(
            child: _buildMenuList(context),
          ),
          _buildFooter(context, _authService),
        ],
      ),
    );
  }

  Widget _buildHeader(User? user) {
    final storeName = _storeName ?? 'TindahanCE';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        color: Colors.teal[400],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.store, size: 30, color: Colors.teal),
          ),
          const SizedBox(height: 12),
          Text(
            storeName,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (user != null)
            Text(
              user.email ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildMenuItem(context, 'Dashboard', Icons.dashboard_outlined, 0),
        _buildMenuItem(context, 'Make a Sale', Icons.point_of_sale_outlined, 1),
        _buildMenuItem(context, 'Products', Icons.inventory_2_outlined, 2),
        _buildMenuItem(context, 'Credit (Utang)', Icons.credit_card_outlined, 3),
        _buildMenuItem(context, 'Transaction History', Icons.history_outlined, 4),
        _buildMenuItem(context, 'Reports', Icons.bar_chart_outlined, 5),
        const Divider(),
        _buildMenuItem(context, 'Settings', Icons.settings_outlined, 6),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, int index) {
    final isSelected = widget.selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.black87),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        ),
      ),
      tileColor: isSelected ? Colors.teal[50] : null,
      onTap: () {
        widget.onSelectItem(index);
      },
    );
  }

  Widget _buildFooter(BuildContext context, AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.red),
        ),
        onTap: () async {
          await authService.signOut();
          // ignore: use_build_context_synchronously
          context.go('/');
        },
      ),
    );
  }
}
