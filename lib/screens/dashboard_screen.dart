import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) navigateToTab;
  const DashboardScreen({super.key, required this.navigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String? _ownerName;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _fetchOwnerName();
    }
  }

  Future<void> _fetchOwnerName() async {
    if (_user == null || !mounted) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_user.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _ownerName = userDoc.data()?['ownerName'];
        });
      }
    } catch (e, s) {
      developer.log(
        'Error fetching owner\'s name',
        name: 'tindahancestro.dashboard',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportId = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (_user == null) {
      return const Center(child: Text("Please log in to see your dashboard."));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_user.uid)
            .collection('daily_reports')
            .doc(reportId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _ownerName == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final reportData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          final double totalSales = (reportData['totalSales'] as num?)?.toDouble() ?? 0.0;
          final int totalTransactions = (reportData['totalTransactions'] as num?)?.toInt() ?? 0;
          final Map<String, int> productSales = (reportData['productSales'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v as int));

          final sortedProducts = productSales.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topProducts = Map.fromEntries(sortedProducts.take(5));

          return RefreshIndicator(
            onRefresh: () async {
              await _fetchOwnerName();
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSalesSummary(totalSales, totalTransactions),
                  const SizedBox(height: 24),
                  _buildTopProducts(topProducts),
                  const SizedBox(height: 24),
                  _buildLowStockAlert(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final displayName = _ownerName ?? 'Tindahan Owner';
    return Text(
      'Welcome, $displayName!',
      style: GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSalesSummary(double totalSales, int transactionCount) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Total Revenue',
            '₱${NumberFormat('#,##0.00').format(totalSales)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _summaryCard(
            'Transactions',
            transactionCount.toString(),
            Icons.receipt_long,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(Map<String, int> topProducts) {
    return Card(
       elevation: 4,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⭐ Top Selling Products', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 15),
            if (topProducts.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('No sales recorded yet today.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ))
            else
              ...topProducts.entries.map((entry) => _productRankItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _productRankItem(String name, int quantity) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.inventory_2_outlined, color: Colors.orange),
      title: Text(
        name,
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        '$quantity sold',
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green.shade600),
      ),
    );
  }

  Widget _buildLowStockAlert() {
    if (_user == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_user.uid).collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allProducts = snapshot.data!.docs;
        final lowStockProducts = allProducts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['stock'] as int? ?? 0) <= 10 && (data['stock'] as int? ?? 0) > 0;
        }).toList();
        
        final outOfStockProducts = allProducts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['stock'] as int? ?? 0) == 0;
        }).toList();


        bool hasProducts = allProducts.isNotEmpty;
        bool hasLowStock = lowStockProducts.isNotEmpty;
        bool hasOutOfStock = outOfStockProducts.isNotEmpty;

        Color cardColor = Colors.green.withAlpha(25);
        Color borderColor = Colors.green.shade200;
        String title = 'Stock Status';
        IconData titleIcon = Icons.check_circle_outline_rounded;

        if(hasOutOfStock || hasLowStock) {
          cardColor = Colors.red.withAlpha(25);
          borderColor = Colors.red.shade200;
          title = 'Stock Alerts';
          titleIcon = Icons.warning_amber_rounded;
        }


        return Card(
          elevation: 2,
          shadowColor: Colors.black.withAlpha(25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: 1),
          ),
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      titleIcon,
                      color: hasOutOfStock || hasLowStock ? Colors.red.shade700 : Colors.green.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: hasOutOfStock || hasLowStock ? Colors.red.shade800 : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (!hasProducts)
                  Text(
                    'You have not added any products yet. Add products to track their stock.',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                  )
                else if (!hasLowStock && !hasOutOfStock)
                  Text(
                    'All products have sufficient stock!',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                  )
                else ...[
                  if(hasOutOfStock)
                  ...outOfStockProducts.map((doc) => _stockAlertItem(doc, isOutOfStock: true)),
                  if(hasLowStock)
                  ...lowStockProducts.map((doc) => _stockAlertItem(doc)),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stockAlertItem(DocumentSnapshot doc, {bool isOutOfStock = false}){
    final data = doc.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(data['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          Text(
            isOutOfStock ? 'Out of Stock' :'Only ${data['stock']} left',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red.shade800),
          ),
        ],
      ),
    );
  }
}
