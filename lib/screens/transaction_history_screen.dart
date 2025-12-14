
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final DateTime dateTime;
  final double amount;
  final String paymentMethod;
  final String? customerName;
  final List<Map<String, dynamic>> items;

  Transaction({
    required this.id,
    required this.dateTime,
    required this.amount,
    required this.paymentMethod,
    this.customerName,
    required this.items,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      amount: (data['amount'] as num).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      customerName: data['customerName'],
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
    );
  }
}

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  Future<void> _showConfirmationDialog(BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          content: Text(content, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllTransactions(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final transactionsSnapshot = await FirebaseFirestore.instance.collection('transactions').get();
      if (transactionsSnapshot.docs.isEmpty) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('No transactions to clear.')));
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in transactionsSnapshot.docs) {
        final transaction = Transaction.fromFirestore(doc);
        await _addTransactionUpdatesToBatch(batch, transaction);
        batch.delete(doc.reference);
      }

      await batch.commit();

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('All transaction history has been cleared.')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('An error occurred while clearing history: $e')),
      );
    }
  }

  Future<void> _addTransactionUpdatesToBatch(WriteBatch batch, Transaction transaction) async {
    for (final item in transaction.items) {
      final productName = item['name'];
      final quantity = item['quantity'];
      final productQuery = await FirebaseFirestore.instance.collection('products').where('name', isEqualTo: productName).limit(1).get();
      if (productQuery.docs.isNotEmpty) {
        final productDocRef = productQuery.docs.first.reference;
        batch.update(productDocRef, {'stock': FieldValue.increment(quantity)});
      }
    }

    if (transaction.paymentMethod == 'Utang' && transaction.customerName != null) {
      final creditQuery = await FirebaseFirestore.instance.collection('credits').where('name', isEqualTo: transaction.customerName).limit(1).get();
      if (creditQuery.docs.isNotEmpty) {
        final creditDocRef = creditQuery.docs.first.reference;
        batch.update(creditDocRef, {'amount': FieldValue.increment(-transaction.amount)});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clear All History', style: TextStyle(fontSize: 16)),
              onPressed: () {
                _showConfirmationDialog(
                  context,
                  title: 'Clear All History?',
                  content: 'This will permanently delete all transaction records and restore product stocks and credit balances. This action cannot be undone.',
                  onConfirm: () => _clearAllTransactions(context),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('transactions').orderBy('dateTime', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No transactions found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  );
                }

                final transactions = snapshot.data!.docs.map((doc) => Transaction.fromFirestore(doc)).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    return TransactionCard(transaction: transactions[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionCard extends StatefulWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  _TransactionCardState createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isExpanded = false;

  Future<void> _deleteTransaction() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final transactionRef = FirebaseFirestore.instance.collection('transactions').doc(widget.transaction.id);

      await _addTransactionUpdatesToBatch(batch, widget.transaction);

      batch.delete(transactionRef);

      await batch.commit();

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Transaction deleted successfully.')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error deleting transaction: $e')));
    }
  }

  Future<void> _addTransactionUpdatesToBatch(WriteBatch batch, Transaction transaction) async {
    for (final item in transaction.items) {
      final productName = item['name'];
      final quantity = item['quantity'];
      final productQuery = await FirebaseFirestore.instance.collection('products').where('name', isEqualTo: productName).limit(1).get();
      if (productQuery.docs.isNotEmpty) {
        final productDocRef = productQuery.docs.first.reference;
        batch.update(productDocRef, {'stock': FieldValue.increment(quantity)});
      }
    }

    if (transaction.paymentMethod == 'Utang' && transaction.customerName != null) {
      final creditQuery = await FirebaseFirestore.instance.collection('credits').where('name', isEqualTo: transaction.customerName).limit(1).get();
      if (creditQuery.docs.isNotEmpty) {
        final creditDocRef = creditQuery.docs.first.reference;
        batch.update(creditDocRef, {'amount': FieldValue.increment(-transaction.amount)});
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Column(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 40),
                const SizedBox(height: 16),
                const Text('Delete Transaction?', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          content: const Text(
            'This will restore stock and update credit if applicable. This action cannot be undone.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteTransaction();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color paymentColor = widget.transaction.paymentMethod == 'Cash' ? const Color(0xFF1ABC9C) : Colors.orange.shade700;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3.0,
      shadowColor: paymentColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: paymentColor, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (isExpanded) => setState(() => _isExpanded = isExpanded),
          trailing: _isExpanded ? const Icon(Icons.expand_less) : const Icon(Icons.expand_more),
          title: _buildCollapsedContent(paymentColor),
          children: [_buildExpandedContent()],
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(Color paymentColor) {
    final formattedDate = DateFormat('MMM d, yyyy - hh:mm a').format(widget.transaction.dateTime);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formattedDate,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (widget.transaction.customerName != null)
                RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                    children: <TextSpan>[
                      const TextSpan(text: 'Customer: ', style: TextStyle(color: Colors.grey)),
                      TextSpan(text: widget.transaction.customerName!, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
               Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '₱${NumberFormat('#,##0.00').format(widget.transaction.amount)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          widget.transaction.paymentMethod,
          style: TextStyle(fontSize: 14, color: paymentColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(thickness: 1, height: 16),
          const Text('Items Purchased:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...widget.transaction.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${item['quantity']}x ${item['name']}', style: const TextStyle(fontSize: 14))),
                  Text('₱${(item['price'] as num).toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                ],
              ),
            );
          }),
          const Divider(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete Transaction', style: TextStyle(color: Colors.red)),
              onPressed: _showDeleteConfirmationDialog,
            ),
          ),
        ],
      ),
    );
  }
}
