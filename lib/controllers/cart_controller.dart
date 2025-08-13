import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../utils/constants.dart';

class CartController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CartItemModel> _cartItems = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<CartItemModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get itemCount => _cartItems.length;

  // Calculate subtotal of all items in cart
  double get subtotal => _cartItems.fold(
    0, (total, item) => total + (item.price * item.quantity));

  // Calculate delivery fee - free for orders over 100
  double get deliveryFee => subtotal > 100 ? 0 : 10.0;

  // Calculate total amount
  double get total => subtotal + deliveryFee;

  // Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message and notify listeners
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Get current user ID or throw error if not logged in
  String _getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  // Reference to the user's cart collection
  CollectionReference _getCartRef() {
    final userId = _getCurrentUserId();
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.cartCollection);
  }

  // Fetch all cart items for current user
  Future<void> fetchCartItems() async {
    _setLoading(true);
    _setError('');

    try {
      final cartRef = _getCartRef();
      final snapshot = await cartRef.orderBy('addedAt', descending: true).get();

      _cartItems = snapshot.docs
          .map((doc) => CartItemModel.fromSnapshot(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch cart items: $e');
      _setLoading(false);
    }
  }

  // Add a product to cart
  Future<bool> addToCart(ProductModel product, {int quantity = 1}) async {
    _setLoading(true);
    _setError('');

    try {
      final userId = _getCurrentUserId();
      final cartRef = _getCartRef();

      // Check if product already exists in cart
      final existingItemQuery = await cartRef
          .where('productId', isEqualTo: product.id)
          .limit(1)
          .get();

      if (existingItemQuery.docs.isNotEmpty) {
        // Update existing item quantity
        final existingItem = existingItemQuery.docs.first;
        final currentQuantity = existingItem.get('quantity') as int;

        await existingItem.reference.update({
          'quantity': currentQuantity + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new item to cart
        final cartItem = CartItemModel(
          id: '', // Firestore will generate ID
          productId: product.id,
          userId: userId,
          name: product.name,
          price: product.discountPrice ?? product.price,
          quantity: quantity,
          imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
          categoryId: product.categoryId,
        );

        await cartRef.add(cartItem.toJson());
      }

      // Refresh cart items
      await fetchCartItems();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add item to cart: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update cart item quantity with optimistic UI update
  Future<bool> updateQuantity(String itemId, int quantity) async {
    if (quantity < 1) {
      return removeFromCart(itemId);
    }

    // Store original quantity in case we need to revert
    int originalQuantity = 1;
    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      originalQuantity = _cartItems[index].quantity;
      // Update local state immediately for responsive UI
      _cartItems[index].quantity = quantity;
      notifyListeners();
    }

    try {
      final cartRef = _getCartRef();
      await cartRef.doc(itemId).update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      // Revert the local change if Firebase update fails
      if (index != -1) {
        _cartItems[index].quantity = originalQuantity;
        notifyListeners();
      }
      _setError('Failed to update quantity: $e');
      return false;
    }
  }

  // Remove an item from cart
  Future<bool> removeFromCart(String itemId) async {
    _setLoading(true);
    _setError('');

    try {
      final cartRef = _getCartRef();
      await cartRef.doc(itemId).delete();

      // Remove item from local list
      _cartItems.removeWhere((item) => item.id == itemId);
      notifyListeners();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to remove item: $e');
      _setLoading(false);
      return false;
    }
  }

  // Clear entire cart
  Future<bool> clearCart() async {
    _setLoading(true);
    _setError('');

    try {
      final cartRef = _getCartRef();
      final batch = _firestore.batch();

      final snapshots = await cartRef.get();
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      _cartItems.clear();
      notifyListeners();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to clear cart: $e');
      _setLoading(false);
      return false;
    }
  }
}
