
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tindahance/models/product.dart';

class ProductService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');

  Future<void> addProduct(Product product) {
    return _productsCollection.add({
      'name': product.name,
      'price': product.price,
      'stock': product.stock,
    });
  }

  Stream<List<Product>> getProducts() {
    return _productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product(
          id: doc.id,
          name: doc['name'],
          price: doc['price'],
          stock: doc['stock'],
        );
      }).toList();
    });
  }

  Future<void> updateProduct(Product product) {
    return _productsCollection.doc(product.id).update({
      'name': product.name,
      'price': product.price,
      'stock': product.stock,
    });
  }

  Future<void> deleteProduct(String productId) {
    return _productsCollection.doc(productId).delete();
  }
}
