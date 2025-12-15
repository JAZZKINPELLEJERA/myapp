
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Models
class Product {
  final String id;
  final String name;
  final double price;
  final int stock;

  Product({required this.id, required this.name, required this.price, required this.stock});

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
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
  _MakeSaleScreenState createState() => _MakeSaleScreenState();
}

class _MakeSaleScreenState extends State<MakeSaleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  final List<CartItem> _cart = [];

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

  double get _totalAmount {
    return _cart.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildProductList()),
        ],
      ),
      floatingActionButton: _cart.isNotEmpty ? _buildCartFab() : null,
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

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var products = snapshot.data!.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((p) => p.name.toLowerCase().contains(_searchTerm.toLowerCase()))
            .toList();

        if (products.isEmpty) {
          return const Center(child: Text('No products found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80), // Space for the FAB
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductTile(product);
          },
        );
      },
    );
  }

  Widget _buildProductTile(Product product) {
    final bool inStock = product.stock > 0;
    final cartQty = _getCartItemQuantity(product.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2.0,
      shadowColor: Colors.black.withOpacity(0.1),
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

  Widget _buildCartFab() {
    return FloatingActionButton.extended(
      onPressed: _showCartSheet,
      label: Text('View Cart - ₱${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      icon: Badge(
        label: Text('${_cart.length}'),
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1ABC9C),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                          Text('Available stock: ${item.product.stock}')
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

            double totalAmount = _cart.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));

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
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                    subtitle: Text('₱${item.product.price.toStringAsFixed(2)} x ${item.quantity} = ₱${(item.product.price * item.quantity).toStringAsFixed(2)}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 28), onPressed: () => updateQuantity(item, -1)),
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
                                        IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1ABC9C), size: 28), onPressed: () => updateQuantity(item, 1)),
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
                                _showPaymentMethodSelection();
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

  void _showPaymentMethodSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  _showCashPaymentDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.credit_card, color: Colors.orange.shade700, size: 30),
                title: const Text('Utang (Credit)', style: TextStyle(fontSize: 18)),
                onTap: () {
                  Navigator.pop(context);
                  _showUtangPaymentDialog();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showCashPaymentDialog() {
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
                Text('Total Amount: ₱${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(
                  controller: cashController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Cash Received', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF1ABC9C))),
              ),
              ElevatedButton(
                onPressed: () {
                  final cashReceived = double.tryParse(cashController.text);
                  if (cashReceived == null) {
                    setDialogState(() => errorMessage = 'Please enter a valid amount.');
                  } else if (cashReceived < _totalAmount) {
                    setDialogState(() => errorMessage = 'Cash received is not enough.');
                  } else {
                    Navigator.pop(context); // Close payment dialog
                    _finalizeSale('Cash', cashReceived: cashReceived);
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

  void _showUtangPaymentDialog() {
    final searchController = TextEditingController();
    String searchTerm = '';
    final StreamController<List<DocumentSnapshot>> streamController = StreamController.broadcast();

    FirebaseFirestore.instance.collection('credits').orderBy('name').get().then((snapshot) {
      if (!streamController.isClosed) streamController.add(snapshot.docs);
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Select Customer'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search or Add New Customer',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      searchTerm = value;
                      FirebaseFirestore.instance
                          .collection('credits')
                          .orderBy('name')
                          .startAt([searchTerm])
                          .endAt(['$searchTerm\uf8ff'])
                          .get()
                          .then((snapshot) {
                        if (!streamController.isClosed) streamController.add(snapshot.docs);
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
                        return const Center(child: Text('No customers found.'));
                      }

                      final customers = snapshot.data!;
                      return ListView.builder(
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customerName = customers[index]['name'] as String;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text(customerName),
                              onTap: () {
                                Navigator.pop(context);
                                _finalizeSale('Utang', customerName: customerName);
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newCustomerName = searchController.text.trim();
                if (newCustomerName.isNotEmpty) {
                  Navigator.pop(context);
                  _finalizeSale('Utang', customerName: newCustomerName);
                }
              },
              child: const Text('Add as New'),
            )
          ],
        );
      },
    ).whenComplete(() => streamController.close());
  }

  void _showReceiptDialog(double cashReceived) {
  final double change = cashReceived - _totalAmount;

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
              _buildReceiptRow('Total', '₱${_totalAmount.toStringAsFixed(2)}', isBold: true),
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
                Navigator.pop(context);
                _clearCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sale completed successfully!')),
                );
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


  Future<void> _finalizeSale(String paymentMethod, {String? customerName, double? cashReceived}) async {
    if (_cart.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final reportId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dailyReportRef = firestore.collection('daily_reports').doc(reportId);

    try {
      await firestore.runTransaction((transaction) async {
        // 1. Read the current daily report
        final reportSnapshot = await transaction.get(dailyReportRef);

        // Initialize new values from the cart
        double newTotalSales = _totalAmount;
        int newTotalTransactions = 1;
        Map<String, int> newProductSales = { for (var item in _cart) item.product.name: item.quantity };

        if (reportSnapshot.exists) {
          // If the report exists, get existing values and add the new ones
          final existingData = reportSnapshot.data() as Map<String, dynamic>;
          final existingTotalSales = (existingData['totalSales'] as num?)?.toDouble() ?? 0.0;
          final existingTotalTransactions = (existingData['totalTransactions'] as num?)?.toInt() ?? 0;
          final existingProductSales = (existingData['productSales'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v as int));
          
          newTotalSales += existingTotalSales;
          newTotalTransactions += existingTotalTransactions;

          newProductSales.forEach((productName, quantity) {
            existingProductSales[productName] = (existingProductSales[productName] ?? 0) + quantity;
          });
          newProductSales = existingProductSales;
        }

        // 2. Create the data for the new/updated report
        final reportData = {
          'totalSales': newTotalSales,
          'totalTransactions': newTotalTransactions,
          'productSales': newProductSales,
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        // 3. Set the updated daily report
        transaction.set(dailyReportRef, reportData);

        // 4. Record the permanent transaction
        final transactionRef = firestore.collection('transactions').doc();
        transaction.set(transactionRef, {
          'dateTime': Timestamp.now(),
          'amount': _totalAmount,
          'paymentMethod': paymentMethod,
          'customerName': customerName,
          'items': _cart.map((item) => {
            'name': item.product.name,
            'quantity': item.quantity,
            'price': item.product.price,
          }).toList(),
        });

        // 5. Update product stock for each item in the cart
        for (var item in _cart) {
          final productRef = firestore.collection('products').doc(item.product.id);
          transaction.update(productRef, {'stock': FieldValue.increment(-item.quantity)});
        }

        // 6. Handle Utang (Credit)
        if (paymentMethod == 'Utang' && customerName != null) {
          // Note: Querying inside a transaction is generally discouraged.
          // This part is kept as is but for larger scale apps should be refactored.
          final creditQuery = await firestore.collection('credits').where('name', isEqualTo: customerName).limit(1).get();
          if (creditQuery.docs.isNotEmpty) {
            final creditDocRef = creditQuery.docs.first.reference;
            transaction.update(creditDocRef, {'amount': FieldValue.increment(_totalAmount)});
          } else {
            final newCreditRef = firestore.collection('credits').doc();
            transaction.set(newCreditRef, {
              'name': customerName,
              'amount': _totalAmount,
              'date': Timestamp.now(),
            });
          }
        }
      });

      // 7. Show receipt/confirmation after the transaction is successful
      if (paymentMethod == 'Cash' && cashReceived != null) {
        _showReceiptDialog(cashReceived);
      } else if (paymentMethod == 'Utang') {
        _clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utang recorded successfully!')),
        );
      }
      
    } catch (e) {
      // Handle any errors from the transaction
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finalizing sale: $e')),
      );
    }
  }
}
