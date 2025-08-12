import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int productCount;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.productCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  // Convert model to JSON for storing in Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'productCount': productCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create model from Firestore JSON data
  factory CategoryModel.fromJson(Map<String, dynamic> json, String id) {
    return CategoryModel(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      productCount: json['productCount'] ?? 0,
      createdAt: json['createdAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp?,
    );
  }

  // Create model from Firestore DocumentSnapshot
  factory CategoryModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return CategoryModel.fromJson(data, snapshot.id);
  }

  // Create a copy of the category with some fields changed
  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? productCount,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
