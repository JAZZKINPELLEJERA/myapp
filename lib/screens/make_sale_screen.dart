import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] as num).toDouble(),
      stock: (data['stock'] as num).toInt(),
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class MakeSaleScreen extends StatefulWidget {
  final Function(int) navigateToTab;

  const MakeSaleScreen({super.key, required this.navigateToTab});

  @override
  MakeSaleScreenState createState() => MakeSaleScreenState();
}

class MakeSaleScreenState extends State<MakeSaleScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';
  final _cart = <CartItem>[];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please log in to make a sale."));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildProductList(user)),
        ],
      ),
      floatingActionButton: _cart.isNotEmpty ? _buildCartFab(user) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search Products',
          prefixIcon: const Icon(Icons.search, color: Colors.black),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.black, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Color(0xFF1ABC9C), width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.black, width: 1.0),
          ),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.black54),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchTerm = '';
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchTerm = value;
          });
        },
      ),
    );
  }

  Widget _buildProductList(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('products')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data!.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((p) => p.name.toLowerCase().contains(_searchTerm.toLowerCase()))
            .toList();

        if (products.isEmpty) {
          return const Center(child: Text('No products found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductTile(products[index]);
          },
        );
      },
    );
  }

  Widget _buildProductTile(Product product) {
    final inStock = product.stock > 0;
    final cartQty = _getCartItemQuantity(product.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2.0,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Color(0xFF1ABC9C), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Price: ₱${product.price.toStringAsFixed(2)} | Stock: ${product.stock}',
          style: TextStyle(color: inStock ? Colors.grey[600] : Colors.red),
        ),
        trailing: Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: Icon(
                Icons.add_shopping_cart,
                color: inStock ? const Color(0xFF1ABC9C) : Colors.grey,
                size: 30,
              ),
              onPressed: inStock ? () => _addToCart(product) : null,
            ),
            if (cartQty > 0)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$cartQty',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartFab(User user) {
    final totalAmount = _cart.fold(0.0, (total, item) => total + (item.product.price * item.quantity));
    return FloatingActionButton.extended(
      onPressed: () => _showCartSheet(user),
      label: Text('View Cart - ₱${totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      icon: Badge(
        label: Text('${_cart.length}'),
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1ABC9C),
    );
  }

  void _showCartSheet(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void showQuantityInputDialog(CartItem item) {
              final quantityController = TextEditingController(text: item.quantity.toString());
              String? errorText;

              showDialog(
                context: context,
                builder: (dialogContext) {
                  return StatefulBuilder(builder: (context, setDialogState) {
                    return AlertDialog(
                      title: Text('Set Quantity for ${item.product.name}'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: quantityController,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              hintText: 'Max: ${item.product.stock}',
                              errorText: errorText,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          Text('Available stock: ${item.product.stock}'),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),                        ElevatedButton(
                          onPressed: () {
                            final newQuantity = int.tryParse(quantityController.text);
                            if (newQuantity == null || newQuantity <= 0) {
                              setDialogState(() => errorText = 'Invalid quantity');
                            } else if (newQuantity > item.product.stock) {
                              setDialogState(() => errorText = 'Exceeds available stock');
                            } else {
                              setModalState(() => item.quantity = newQuantity);
                              setState(() {}); // Update main screen FAB
                              Navigator.pop(dialogContext);
                            }
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    );
                  });
                },
              );
            }

            void updateQuantity(CartItem item, int change) {
              setModalState(() {
                final newQuantity = item.quantity + change;
                if (newQuantity > 0 && newQuantity <= item.product.stock) {
                  item.quantity = newQuantity;
                }
              });
              setState(() {}); // Update main screen FAB
            }

            void removeItem(int index) {
              setModalState(() {
                _cart.removeAt(index);
              });
              setState(() {});
            }

            final totalAmount = _cart.fold(0.0, (total, item) => total + (item.product.price * item.quantity));

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Shopping Cart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _cart.isEmpty
                            ? const Center(child: Text("Your cart is empty."))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: _cart.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final item = _cart[index];
                                  return ListTile(
                                    title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        '₱${item.product.price.toStringAsFixed(2)} x ${item.quantity} = ₱${(item.product.price * item.quantity).toStringAsFixed(2)}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 28),
                                            onPressed: () => updateQuantity(item, -1)),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => showQuantityInputDialog(item),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade400),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text('${item.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1ABC9C), size: 28),
                                            onPressed: () => updateQuantity(item, 1)),
                                      ],
                                    ),
                                    leading: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
                                      onPressed: () => removeItem(index),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 20, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('₱${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1ABC9C))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _cart.isNotEmpty
                            ? () {
                                Navigator.pop(context); // Close cart sheet
                                _showPaymentMethodSelection(user, totalAmount);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1ABC9C),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                        child: const Text('Proceed to Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showPaymentMethodSelection(User user, double totalAmount) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Payment Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.money, color: Color(0xFF1ABC9C), size: 30),
                title: const Text('Cash', style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  _showCashPaymentDialog(user, totalAmount);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.credit_card, color: Colors.orange.shade700, size: 30),
                title: const Text('Utang (Credit)', style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  _showUtangPaymentDialog(user, totalAmount);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showCashPaymentDialog(User user, double totalAmount) {
    final cashController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Cash Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total Amount: ₱${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(
                  controller: cashController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Cash Received', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                if (errorMessage != null)Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF1ABC9C))),
              ),
              ElevatedButton(
                onPressed: () async {
                  final cashReceived = double.tryParse(cashController.text);
                  if (cashReceived == null || cashReceived <= 0) {
                    setDialogState(() => errorMessage = 'Please enter a valid amount.');
                  } else if (cashReceived < totalAmount) {
                    setDialogState(() => errorMessage = 'Cash received is not enough.');
                  } else {
                    if (!mounted) return;
                    Navigator.pop(context);
                    await _finalizeSale(user, 'Cash', totalAmount, cashReceived: cashReceived);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Confirm Sale'),
              )
            ],
          );
        });
      },
    );
  }

  void _showUtangPaymentDialog(User user, double totalAmount) {
  final searchController = TextEditingController();
  final streamController = StreamController<List<DocumentSnapshot>>.broadcast();

  // Initial fetch of all customers
  FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('credits')
      .orderBy('name')
      .get()
      .then((snapshot) {
    if (!streamController.isClosed) {
      streamController.add(snapshot.docs);
    }
  });

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Center(child: Text('Select or Add Customer', style: TextStyle(fontWeight: FontWeight.bold))),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('credits')
                        .orderBy('name')
                        .where('name', isGreaterThanOrEqualTo: value)
                        .where('name', isLessThanOrEqualTo: '$value\uf8ff')
                        .get()
                        .then((snapshot) {
                      if (!streamController.isClosed) {
                        streamController.add(snapshot.docs);
                      }
                    });
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: streamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 50, color: Colors.grey),
                            const SizedBox(height: 10),
                            const Text('No customers found.', style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 5),
                            Text('Try a different search or add a new one.', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      );
                    }

                    final customers = snapshot.data!;
                    return ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        final customerName = customer['name'] as String;
                        final creditAmount = (customer['amount'] as num?)?.toDouble() ?? 0.0;
                        return Card(
                          elevation: 2.0,
                          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF1ABC9C),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Current Debt: ₱${creditAmount.toStringAsFixed(2)}'),
                            onTap: () async {
                              if (!mounted) return;
                              Navigator.pop(context); // Close the selection dialog
                              await _finalizeSale(user, 'Utang', totalAmount, customerName: customerName);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add as New', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1ABC9C), // Teal color
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newCustomerName = searchController.text.trim();
              if (newCustomerName.isNotEmpty) {
                if (!mounted) return;
                Navigator.pop(context); // Close the dialog
                await _finalizeSale(user, 'Utang', totalAmount, customerName: newCustomerName);
              }
            },
          )
        ],
      );
    },
  ).whenComplete(() => streamController.close());
}


  void _showReceiptDialog(double cashReceived, double totalAmount) {
    final change = cashReceived - totalAmount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, color: Color(0xFF1ABC9C), size: 40),
                SizedBox(height: 8),
                Text('TINDAHANCE Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                ..._cart.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${item.quantity}x ${item.product.name}')),
                          Text('₱${(item.quantity * item.product.price).toStringAsFixed(2)}'),
                        ],
                      ),
                    )),
                const Divider(thickness: 1.5, height: 20),
                _buildReceiptRow('Total', '₱${totalAmount.toStringAsFixed(2)}', isBold: true),
                _buildReceiptRow('Cash Received', '₱${cashReceived.toStringAsFixed(2)}'),
                const SizedBox(height: 10),
                _buildReceiptRow('Change', '₱${change.toStringAsFixed(2)}', isBold: true, fontSize: 18),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (!mounted) return;
                  Navigator.pop(context);
                  _clearCart();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale completed successfully!')));
                },
                child: const Text('OK & New Sale'),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildReceiptRow(String title, String amount, {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
          Text(amount, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
        ],
      ),
    );
  }

  Future<void> _finalizeSale(User user, String paymentMethod, double totalAmount, {String? customerName, double? cashReceived}) async {
    if (_cart.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);
    final reportId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dailyReportRef = userRef.collection('daily_reports').doc(reportId);

    try {
      await firestore.runTransaction((transaction) async {
        final reportSnapshot = await transaction.get(dailyReportRef);

        double newTotalSales = totalAmount;
        int newTotalTransactions = 1;
        final newProductSales = {for (var item in _cart) item.product.name: item.quantity};

        if (reportSnapshot.exists) {
          final existingData = reportSnapshot.data() as Map<String, dynamic>;
          newTotalSales += (existingData['totalSales'] as num?)?.toDouble() ?? 0.0;
          newTotalTransactions += (existingData['totalTransactions'] as num?)?.toInt() ?? 0;
          final existingProductSales = (existingData['productSales'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v as int));

          for (var entry in newProductSales.entries) {
            existingProductSales[entry.key] = (existingProductSales[entry.key] ?? 0) + entry.value;
          }
          newProductSales.addEntries(existingProductSales.entries);
        }

        final reportData = {
          'totalSales': newTotalSales,
          'totalTransactions': newTotalTransactions,
          'productSales': newProductSales,
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        transaction.set(dailyReportRef, reportData);

        final transactionRef = userRef.collection('transactions').doc();
        transaction.set(transactionRef, {
          'dateTime': Timestamp.now(),
          'amount': totalAmount,
          'paymentMethod': paymentMethod,
          'customerName': customerName,
          'items': _cart.map((item) => {
                'name': item.product.name,
                'quantity': item.quantity,
                'price': item.product.price,
              }).toList(),
        });

        for (var item in _cart) {
          final productRef = userRef.collection('products').doc(item.product.id);
          transaction.update(productRef, {'stock': FieldValue.increment(-item.quantity)});
        }

        if (paymentMethod == 'Utang' && customerName != null) {
          final creditCollectionRef = userRef.collection('credits');
          final creditQuery = await creditCollectionRef.where('name', isEqualTo: customerName).limit(1).get();

          if (creditQuery.docs.isNotEmpty) {
            final creditDocRef = creditQuery.docs.first.reference;
            transaction.update(creditDocRef, {'amount': FieldValue.increment(totalAmount)});
          } else {
            final newCreditRef = creditCollectionRef.doc();
            transaction.set(newCreditRef, {
              'name': customerName,
              'amount': totalAmount,
              'date': Timestamp.now(),
            });
          }
        }
      });

      if (!mounted) return;
      if (paymentMethod == 'Cash' && cashReceived != null) {
        _showReceiptDialog(cashReceived, totalAmount);
      } else if (paymentMethod == 'Utang') {
        _clearCart();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utang recorded successfully!')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error finalizing sale: $e')));
    }
  }

  void _addToCart(Product product) {
    setState(() {
      if (product.stock <= 0) return;

      for (var item in _cart) {
        if (item.product.id == product.id) {
          if (item.quantity < product.stock) {
            item.quantity++;
          }
          return;
        }
      }
      _cart.add(CartItem(product: product));
    });
  }

  int _getCartItemQuantity(String productId) {
    for (var item in _cart) {
      if (item.product.id == productId) {
        return item.quantity;
      }
    }
    return 0;
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }
}
