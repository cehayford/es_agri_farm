import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
    };
  }

  double get totalPrice => price * quantity;
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItemModel> items;
  final double subtotal;
  final double shippingFee;
  final double tax;
  final double total;
  final Map<String, dynamic> shippingAddress;
  final String status;
  final DateTime orderDate;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.tax,
    required this.total,
    required this.shippingAddress,
    required this.status,
    required this.orderDate,
  });

  factory OrderModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    List<OrderItemModel> orderItems = [];
    if (data['items'] != null) {
      orderItems = List<OrderItemModel>.from(
        (data['items'] as List).map((item) => OrderItemModel.fromJson(item))
      );
    }

    return OrderModel(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      items: orderItems,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      shippingFee: (data['shippingFee'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      shippingAddress: Map<String, dynamic>.from(data['shippingAddress'] ?? {}),
      status: data['status'] ?? AppConstants.orderPending,
      orderDate: (data['orderDate'] as Timestamp).toDate(),
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    List<OrderItemModel> orderItems = [];
    if (json['items'] != null) {
      orderItems = List<OrderItemModel>.from(
        (json['items'] as List).map((item) => OrderItemModel.fromJson(item))
      );
    }

    return OrderModel(
      id: docId ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: orderItems,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      shippingFee: (json['shippingFee'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      shippingAddress: Map<String, dynamic>.from(json['shippingAddress'] ?? {}),
      status: json['status'] ?? AppConstants.orderPending,
      orderDate: json['orderDate'] != null
          ? (json['orderDate'] is Timestamp
              ? (json['orderDate'] as Timestamp).toDate()
              : DateTime.parse(json['orderDate']))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'tax': tax,
      'total': total,
      'shippingAddress': shippingAddress,
      'status': status,
      'orderDate': Timestamp.fromDate(orderDate),
    };
  }

  // Get the formatted date
  String get formattedDate {
    return '${orderDate.day.toString().padLeft(2, '0')}/${orderDate.month.toString().padLeft(2, '0')}/${orderDate.year}';
  }

  // Get a human-readable status
  String get statusText {
    switch (status) {
      case AppConstants.orderPending:
        return 'Pending';
      case AppConstants.orderCompleted:
        return 'Completed';
      case AppConstants.orderCancelled:
        return 'Cancelled';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case AppConstants.orderPending:
      case 'processing':
        return 'orange';  // Will be handled in UI
      case AppConstants.orderCompleted:
      case 'delivered':
        return 'green';   // Will be handled in UI
      case AppConstants.orderCancelled:
        return 'red';     // Will be handled in UI
      case 'shipped':
        return 'blue';    // Will be handled in UI
      default:
        return 'grey';    // Will be handled in UI
    }
  }

  // Get the total number of items
  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}
