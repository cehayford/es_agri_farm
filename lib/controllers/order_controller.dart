import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/shipping_address_model.dart';
import '../utils/constants.dart';

class OrderController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasOrders => _orders.isNotEmpty;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Fetch orders for a user
  Future<void> fetchOrders(String userId) async {
    _setLoading(true);
    _setError('');

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .get();

      _orders = snapshot.docs
          .map((doc) => OrderModel.fromSnapshot(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch orders: $e');
      _setLoading(false);
    }
  }

  // Get order details
  Future<OrderModel?> getOrderDetails(String orderId) async {
    _setLoading(true);
    _setError('');

    try {
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        final order = OrderModel.fromSnapshot(doc);
        _selectedOrder = order;
        _setLoading(false);
        return order;
      } else {
        _setError('Order not found');
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _setError('Failed to get order details: $e');
      _setLoading(false);
      return null;
    }
  }

  // Create a new order
  Future<OrderModel?> createOrder({
    required String userId,
    required List<OrderItemModel> items,
    required double subtotal,
    required double shippingFee,
    required double tax,
    required double total,
    required ShippingAddressModel shippingAddress,
  }) async {
    _setLoading(true);
    _setError('');

    try {
      // Create a new order document
      final docRef = _firestore.collection(AppConstants.ordersCollection).doc();

      final order = OrderModel(
        id: docRef.id,
        userId: userId,
        items: items,
        subtotal: subtotal,
        shippingFee: shippingFee,
        tax: tax,
        total: total,
        shippingAddress: shippingAddress.toJson(),
        status: AppConstants.orderPending,
        orderDate: DateTime.now(),
      );

      await docRef.set(order.toJson());

      // Refresh the orders list
      await fetchOrders(userId);

      _setLoading(false);
      return order;
    } catch (e) {
      _setError('Failed to create order: $e');
      _setLoading(false);
      return null;
    }
  }

  // Cancel an order
  Future<bool> cancelOrder(String orderId, String userId) async {
    _setLoading(true);
    _setError('');

    try {
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({'status': AppConstants.orderCancelled});

      // Refresh the orders list
      await fetchOrders(userId);

      // Update selected order if it's the one that was cancelled
      if (_selectedOrder != null && _selectedOrder!.id == orderId) {
        await getOrderDetails(orderId);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to cancel order: $e');
      _setLoading(false);
      return false;
    }
  }

  // Set selected order
  void selectOrder(String orderId) {
    _selectedOrder = _orders.firstWhere((o) => o.id == orderId);
    notifyListeners();
  }
}
