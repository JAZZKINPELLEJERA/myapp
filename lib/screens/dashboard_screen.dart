
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) navigateToTab;

  const DashboardScreen({super.key, required this.navigateToTab});

  Stream<double> get TodaysSales {
    final now = DateTime.now();
    final startOfToday = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final endOfToday = Timestamp.fromDate(DateTime(now.year, now.month, now.day, 23, 59, 59));

    return FirebaseFirestore.instance
        .collection('transactions')
        .where('dateTime', isGreaterThanOrEqualTo: startOfToday)
        .where('dateTime', isLessThanOrEqualTo: endOfToday)
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (final doc in snapshot.docs) {
        total += doc['amount'] as double;
      }
      return total;
    });
  }

  Stream<double> get TotalCredit {
    return FirebaseFirestore.instance.collection('credits').snapshots().map((snapshot) {
      double total = 0.0;
      for (final doc in snapshot.docs) {
        total += doc['amount'] as double;
      }
      return total;
    });
  }

  Stream<List<DocumentSnapshot>> get LowStockProducts {
    return FirebaseFirestore.instance
        .collection('products')
        .where('stock', isLessThan: 10)
        .orderBy('stock')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTodaysSalesCard(),
          const SizedBox(height: 16),
          _buildTotalCreditCard(),
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 12),
          _buildQuickActionButtons(context),
          const SizedBox(height: 24),
          _buildLowStockSection(),
        ],
      ),
    );
  }

  Widget _buildTodaysSalesCard() {
    return Card(
      elevation: 4.0,
      shadowColor: const Color(0xFF1ABC9C).withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Sales',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 10),
            StreamBuilder<double>(
              stream: TodaysSales,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.hasError) {
                  return const Text(
                    '₱0.00',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1ABC9C)),
                  );
                }
                final totalSales = snapshot.data!;
                return Text(
                  '₱${NumberFormat('#,##0.00', 'en_US').format(totalSales)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1ABC9C)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCreditCard() {
    return Card(
      elevation: 4.0,
      shadowColor: Colors.orange.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Outstanding Credit',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 10),
            StreamBuilder<double>(
              stream: TotalCredit,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.hasError) {
                  return Text(
                    '₱0.00',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                  );
                }
                final totalCredit = snapshot.data!;
                return Text(
                  '₱${NumberFormat('#,##0.00', 'en_US').format(totalCredit)}',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _quickActionButton(context, icon: Icons.add_shopping_cart, label: 'New Sale', onTap: () => navigateToTab(1)),
        _quickActionButton(context, icon: Icons.add_circle, label: 'New Product', onTap: () => navigateToTab(2)),
      ],
    );
  }

  Widget _quickActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 40, color: const Color(0xFF1ABC9C)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        ],
      ),
    );
  }

  Widget _buildLowStockSection() {
    return Card(
      elevation: 4.0,
      shadowColor: Colors.red.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Low on Stock',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<DocumentSnapshot>>(
              stream: LowStockProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty || snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'All products are well-stocked!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }
                final lowStockProducts = snapshot.data!;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lowStockProducts.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final product = lowStockProducts[index];
                    final productName = product['name'] as String;
                    final stock = product['stock'] as int;
                    return ListTile(
                      title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text(
                        '$stock left',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
