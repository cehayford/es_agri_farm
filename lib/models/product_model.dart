import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final int quantity;
  final bool inStock;
  final String categoryId;
  final String categoryName;
  final List<String> imageUrls;
  final List<String> tags;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  // Fields for livestock products
  final String? breed;
  final String? age;
  final String? gender;
  final double? weight;
  final bool? isVaccinated;
  final String? healthStatus;

  // Fields for plant products
  final String? plantType;
  final String? growthStage;
  final String? careInstructions;
  final String? harvestSeason;
  final bool? isOrganic;

  // Common optional fields for both types
  final Map<String, dynamic>? specifications;
  final Map<String, dynamic>? nutritionalInfo;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.quantity,
    required this.inStock,
    required this.categoryId,
    required this.categoryName,
    required this.imageUrls,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,

    // Livestock fields
    this.breed,
    this.age,
    this.gender,
    this.weight,
    this.isVaccinated,
    this.healthStatus,

    // Plant fields
    this.plantType,
    this.growthStage,
    this.careInstructions,
    this.harvestSeason,
    this.isOrganic,

    // Common fields
    this.specifications,
    this.nutritionalInfo,
  });

  // Convert model to JSON for storing in Firestore
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'inStock': inStock,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrls': imageUrls,
      'tags': tags,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };

    // Add optional fields only if they exist
    if (discountPrice != null) data['discountPrice'] = discountPrice;

    // Livestock fields
    if (breed != null) data['breed'] = breed;
    if (age != null) data['age'] = age;
    if (gender != null) data['gender'] = gender;
    if (weight != null) data['weight'] = weight;
    if (isVaccinated != null) data['isVaccinated'] = isVaccinated;
    if (healthStatus != null) data['healthStatus'] = healthStatus;

    // Plant fields
    if (plantType != null) data['plantType'] = plantType;
    if (growthStage != null) data['growthStage'] = growthStage;
    if (careInstructions != null) data['careInstructions'] = careInstructions;
    if (harvestSeason != null) data['harvestSeason'] = harvestSeason;
    if (isOrganic != null) data['isOrganic'] = isOrganic;

    // Common fields
    if (specifications != null) data['specifications'] = specifications;
    if (nutritionalInfo != null) data['nutritionalInfo'] = nutritionalInfo;

    return data;
  }

  // Create model from Firestore JSON data
  factory ProductModel.fromJson(Map<String, dynamic> json, String id) {
    return ProductModel(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 0,
      inStock: json['inStock'] as bool? ?? false,
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp?,

      // Livestock fields
      breed: json['breed'] as String?,
      age: json['age'] as String?,
      gender: json['gender'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      isVaccinated: json['isVaccinated'] as bool?,
      healthStatus: json['healthStatus'] as String?,

      // Plant fields
      plantType: json['plantType'] as String?,
      growthStage: json['growthStage'] as String?,
      careInstructions: json['careInstructions'] as String?,
      harvestSeason: json['harvestSeason'] as String?,
      isOrganic: json['isOrganic'] as bool?,

      // Common fields
      specifications: json['specifications'] as Map<String, dynamic>?,
      nutritionalInfo: json['nutritionalInfo'] as Map<String, dynamic>?,
    );
  }

  // Create model from Firestore DocumentSnapshot
  factory ProductModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return ProductModel.fromJson(data, snapshot.id);
  }

  // Create a copy of the product with some fields changed
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    int? quantity,
    bool? inStock,
    String? categoryId,
    String? categoryName,
    List<String>? imageUrls,
    List<String>? tags,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? breed,
    String? age,
    String? gender,
    double? weight,
    bool? isVaccinated,
    String? healthStatus,
    String? plantType,
    String? growthStage,
    String? careInstructions,
    String? harvestSeason,
    bool? isOrganic,
    Map<String, dynamic>? specifications,
    Map<String, dynamic>? nutritionalInfo,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      quantity: quantity ?? this.quantity,
      inStock: inStock ?? this.inStock,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      isVaccinated: isVaccinated ?? this.isVaccinated,
      healthStatus: healthStatus ?? this.healthStatus,
      plantType: plantType ?? this.plantType,
      growthStage: growthStage ?? this.growthStage,
      careInstructions: careInstructions ?? this.careInstructions,
      harvestSeason: harvestSeason ?? this.harvestSeason,
      isOrganic: isOrganic ?? this.isOrganic,
      specifications: specifications ?? this.specifications,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
    );
  }

  // Calculate discount percentage if there's a discount price
  int? get discountPercentage {
    if (discountPrice != null && price > 0) {
      final percentage = ((price - discountPrice!) / price) * 100;
      return percentage.round();
    }
    return null;
  }

  // Check if the product is a livestock product
  bool get isLivestock {
    return breed != null || age != null || gender != null || weight != null ||
           isVaccinated != null || healthStatus != null;
  }

  // Check if the product is a plant product
  bool get isPlant {
    return plantType != null || growthStage != null || careInstructions != null ||
           harvestSeason != null || isOrganic != null;
  }
}
