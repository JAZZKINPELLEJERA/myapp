import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double _totalSales = 0.0;
  Map<String, int> _topSellingProducts = {};
  Map<String, int> _leastSellingProducts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final reportId = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('products').get(),
        FirebaseFirestore.instance.collection('daily_reports').doc(reportId).get(),
      ]);

      if (!mounted) return;

      final productsSnapshot = results[0] as QuerySnapshot;
      final reportSnapshot = results[1] as DocumentSnapshot;

      final allProductNames = productsSnapshot.docs.map((doc) => doc['name'] as String).toSet();
      final reportData = reportSnapshot.data() as Map<String, dynamic>?;

      if (reportData == null) {
        setState(() {
          _totalSales = 0.0;
          _topSellingProducts = {};
          _leastSellingProducts = {for (var name in allProductNames) name: 0};
          _isLoading = false;
        });
        return;
      }

      final totalSales = (reportData['totalSales'] as num?)?.toDouble() ?? 0.0;
      final productSalesData = reportData['productSales'] as Map<String, dynamic>? ?? {};
      final productSales = productSalesData.map((key, value) => MapEntry(key, (value as num).toInt()));

      final soldProductNames = productSales.keys.toSet();
      final unsoldProductNames = allProductNames.difference(soldProductNames);

      final sortedTopProducts = productSales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _totalSales = totalSales;
        _topSellingProducts = Map.fromEntries(sortedTopProducts.take(5));
        _leastSellingProducts = {for (var name in unsoldProductNames) name: 0};
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching report data: $e')),
      );
    }
  }

  Future<void> _showResetConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Column(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 40),
                const SizedBox(height: 16),
                Text('Permanently Delete?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          content: Text(
            'This will delete all of today\'s sales records. This action cannot be undone.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600], foregroundColor: Colors.white),
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
              child: const Text('Confirm & Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _resetReportData();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetReportData() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!scaffoldMessenger.mounted) return;

    final reportId = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final reportDoc = FirebaseFirestore.instance.collection('daily_reports').doc(reportId);
      await reportDoc.delete();

      scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Today\'s sales data has been permanently deleted.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));

      // After deleting, refresh the data to show the empty state
      await _fetchReportData();

    } catch (e) {
      if (scaffoldMessenger.mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('An error occurred while deleting data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text('Today\'s Report', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
        backgroundColor: Colors.white,
        elevation: 1.0,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _fetchReportData,
            color: Colors.blue[700],
          ),
          IconButton(
            icon: Icon(Icons.delete_forever, color: Colors.red[700]),
            tooltip: 'Permanently Delete Today\'s Data',
            onPressed: _showResetConfirmationDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReportData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(_totalSales),
                    const SizedBox(height: 24),
                    _buildProductPerformanceCard(_topSellingProducts, _leastSellingProducts),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(double totalSales) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Sales Today',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 8),
            Text(
              '₱${NumberFormat('#,##0.00').format(totalSales)}',
              style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPerformanceCard(Map<String, int> topSelling, Map<String, int> leastSelling) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Performance',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 20),
            _buildProductList('⭐ Top Selling', topSelling, Colors.green.shade600),
            const SizedBox(height: 28),
            _buildProductList('🚫 Not Yet Sold', leastSelling, Colors.orange.shade800, showZeroAsNotSold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(String title, Map<String, int> products, Color indicatorColor, {bool showZeroAsNotSold = false}) {
    final entries = products.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF2C3E50)),
        ),
        const SizedBox(height: 16),
        if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              title.contains('Top') ? 'No sales recorded yet.' : 'All products have at least one sale!',
              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 15),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final String salesText = (showZeroAsNotSold && entry.value == 0) 
                  ? 'Not sold yet' 
                  : '${entry.value} sold';

              return Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: indicatorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: indicatorColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16, color: const Color(0xFF34495E)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    salesText,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF7F8C8D), fontSize: 15),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
