
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showAddProductModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) => _AddProductDialog(onError: _showErrorSnackbar),
    );
  }

  void _showEditProductModal(String docId, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) => _EditProductDialog(docId: docId, product: product, onError: _showErrorSnackbar),
    );
  }

  void _showDeleteConfirmationDialog(String docId, String productName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete "$productName"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                FirebaseFirestore.instance.collection('products').doc(docId).delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductModal,
        backgroundColor: const Color(0xFF1ABC9C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search Products...',
          prefixIcon: const Icon(Icons.search, color: Colors.black),
          filled: true,
          fillColor: Colors.grey[200],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.black, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(color: Colors.black, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No products yet. Add one!', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          );
        }

        var docs = snapshot.data!.docs;
        final filteredDocs = _searchText.isEmpty
            ? docs
            : docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['name'] as String? ?? '').toLowerCase().contains(_searchText.toLowerCase());
              }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text('No products match your search.', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var doc = filteredDocs[index];
            return _buildProductCard(doc.data() as Map<String, dynamic>, doc.id);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, String docId) {
    String name = product['name'] ?? 'No Name';
    double price = (product['price'] ?? 0.0).toDouble();
    int stock = (product['stock'] ?? 0).toInt();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3.0,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: Color(0xFF1ABC9C), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                  const SizedBox(height: 6),
                  Text('Price: ₱${price.toStringAsFixed(2)} | Stock: $stock', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showEditProductModal(docId, product)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _showDeleteConfirmationDialog(docId, name)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Stateful Dialog for Adding a Product
class _AddProductDialog extends StatefulWidget {
  final Function(String) onError;
  const _AddProductDialog({required this.onError});

  @override
  __AddProductDialogState createState() => __AddProductDialogState();
}

class __AddProductDialogState extends State<_AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      title: const Center(child: Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22))),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a price';
                if (double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: stockController,
              decoration: const InputDecoration(labelText: 'Stock Quantity'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a stock quantity';
                if (int.tryParse(value) == null) return 'Please enter a valid whole number';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(child: const Text('Cancel', style: TextStyle(color: Color(0xFF1ABC9C))), onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1ABC9C)), // Teal color
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              FirebaseFirestore.instance.collection('products').add({
                'name': nameController.text,
                'price': double.parse(priceController.text),
                'stock': int.parse(stockController.text),
              });
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Stateful Dialog for Editing a Product
class _EditProductDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> product;
  final Function(String) onError;

  const _EditProductDialog({required this.docId, required this.product, required this.onError});

  @override
  __EditProductDialogState createState() => __EditProductDialogState();
}

class __EditProductDialogState extends State<_EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController stockController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product['name']);
    priceController = TextEditingController(text: widget.product['price'].toString());
    stockController = TextEditingController(text: widget.product['stock'].toString());
  }

  void _showUpdateConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Update'),
        content: Text('Are you sure you want to change to "${nameController.text}"?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
            onPressed: () {
              FirebaseFirestore.instance.collection('products').doc(widget.docId).update({
                'name': nameController.text,
                'price': double.parse(priceController.text),
                'stock': int.parse(stockController.text),
              });
              Navigator.of(ctx).pop(); // Close confirmation dialog
              Navigator.of(context).pop(); // Close edit dialog
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      title: const Center(child: Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22))),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a price';
                if (double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: stockController,
              decoration: const InputDecoration(labelText: 'Stock Quantity'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a stock quantity';
                if (int.tryParse(value) == null) return 'Please enter a valid whole number';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          onPressed: () {
            bool hasChanged = nameController.text != widget.product['name'] ||
                                priceController.text != widget.product['price'].toString() ||
                                stockController.text != widget.product['stock'].toString();

            if (!hasChanged) {
              widget.onError('No changes were made.');
              return;
            }

            if (_formKey.currentState!.validate()) {
              _showUpdateConfirmationDialog();
            }
          },
          child: const Text('Update', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
