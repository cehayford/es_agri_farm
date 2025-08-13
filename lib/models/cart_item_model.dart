import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String id;
  final String productId;
  final String userId;
  final String name;
  final double price;
  int quantity;
  final String imageUrl;
  final String categoryId;
  final Timestamp? addedAt;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.categoryId,
    this.addedAt,
  });

  double get totalPrice => price * quantity;

  // Convert model to JSON for storing in Firestore
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'userId': userId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'addedAt': addedAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Create model from Firestore JSON data
  factory CartItemModel.fromJson(Map<String, dynamic> json, String id) {
    return CartItemModel(
      id: id,
      productId: json['productId'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: json['imageUrl'] ?? '',
      categoryId: json['categoryId'] ?? '',
      addedAt: json['addedAt'] as Timestamp?,
    );
  }

  // Create model from Firestore DocumentSnapshot
  factory CartItemModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return CartItemModel.fromJson(data, snapshot.id);
  }

  // Create a copy of this cart item with some fields changed
  CartItemModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
    String? categoryId,
    Timestamp? addedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
