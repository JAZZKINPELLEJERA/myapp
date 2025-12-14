
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  _CreditScreenState createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  String _sortOrder = 'Highest to Lowest';
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  void _showPaymentResultDialog({required BuildContext context, required double originalAmount, required double paidAmount, required double change}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF1ABC9C), size: 70),
              const SizedBox(height: 20),
              const Text('Payment Successful', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildReceiptRow('Total Utang:', originalAmount),
              _buildReceiptRow('Amount Paid:', paidAmount),
              const Divider(thickness: 1, height: 25),
              _buildReceiptRow('Change:', change, isTotal: true),
              const SizedBox(height: 30),
              ElevatedButton(
                 style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text('OK', style: TextStyle(fontSize: 16)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text('₱${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: isTotal ? 22 : 18, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, color: isTotal ? Colors.black : Colors.black87)),
        ],
      ),
    );
  }

  void _showPayDialog(DocumentSnapshot credit) {
    final amountController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final creditData = credit.data() as Map<String, dynamic>;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              title: Text('Pay Credit for ${creditData['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount Due: ₱${(creditData['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter payment amount',
                      prefixText: '₱',
                      filled: true,
                      fillColor: Colors.grey[100],
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFF1ABC9C), width: 1.5)),
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF1ABC9C), fontSize: 16)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1ABC9C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Confirm Payment', style: TextStyle(fontSize: 16)),
                  onPressed: () async {
                    final paidAmount = double.tryParse(amountController.text);
                    if (paidAmount == null || paidAmount <= 0) {
                      setDialogState(() => errorMessage = 'Please enter a valid amount.');
                      return;
                    }

                    final originalAmount = (creditData['amount'] as num).toDouble();

                    try {
                      if (paidAmount < originalAmount) {
                        // Partial Payment
                        await FirebaseFirestore.instance.collection('credits').doc(credit.id).update({'amount': FieldValue.increment(-paidAmount)});
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Partial payment of ₱${paidAmount.toStringAsFixed(2)} received.')));
                      } else {
                        // Full Payment or Overpayment
                        final change = paidAmount - originalAmount;
                        await FirebaseFirestore.instance.collection('credits').doc(credit.id).delete();
                        Navigator.of(context).pop();
                        _showPaymentResultDialog(context: this.context, originalAmount: originalAmount, paidAmount: paidAmount, change: change);
                      }
                    } catch (e) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing payment: $e')));
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildSearchBarAndFilter(),
          Expanded(
            child: _buildCreditList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.black, weight: 800),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: const BorderSide(color: Colors.black, width: 1.0)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: const BorderSide(color: Color(0xFF1ABC9C), width: 2.0)),
              ),
               onChanged: (value) => setState(() => _searchTerm = value),
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterPopupMenu(),
        ],
      ),
    );
  }

  Widget _buildFilterPopupMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
         boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.filter_list, color: Colors.grey[900]),
        onSelected: (String newValue) => setState(() => _sortOrder = newValue),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'Highest to Lowest',
            child: ListTile(leading: Icon(Icons.arrow_downward, color: Color(0xFF1ABC9C)), title: Text('Highest to Lowest')),
          ),
          const PopupMenuItem<String>(
            value: 'Lowest to Highest',
             child: ListTile(leading: Icon(Icons.arrow_upward, color: Color(0xFF1ABC9C)), title: Text('Lowest to Highest')),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditList() {
    Query query = FirebaseFirestore.instance.collection('credits');

     if (_searchTerm.isNotEmpty) {
      query = query.where('name', isGreaterThanOrEqualTo: _searchTerm).where('name', isLessThanOrEqualTo: '$_searchTerm\uf8ff');
    }
    
    query = query.orderBy('amount', descending: _sortOrder == 'Highest to Lowest');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
           return Center(
            child: Text(
              _searchTerm.isNotEmpty 
                ? 'No results found for "$_searchTerm"'
                : 'No outstanding credits.',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          );
        }

        final credits = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8.0),
          itemCount: credits.length,
          itemBuilder: (context, index) {
            final credit = credits[index];
            return _buildCreditCard(credit);
          },
        );
      },
    );
  }

  Widget _buildCreditCard(DocumentSnapshot credit) {
    final creditData = credit.data() as Map<String, dynamic>;
    final date = (creditData['date'] as Timestamp).toDate();
    final formattedDate = DateFormat.yMMMd().format(date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(creditData['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text('₱${(creditData['amount'] as num).toStringAsFixed(2)} – $formattedDate', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _showPayDialog(credit),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                ),
                child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
