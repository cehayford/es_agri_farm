import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product_model.dart';
import '../controllers/category_controller.dart';
import '../utils/constants.dart';

class ProductController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  CategoryController _categoryController;

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _error = '';

  // Constructor with CategoryController dependency
  ProductController(this._categoryController);

  // Method to update the category controller reference
  ProductController updateCategoryController(CategoryController categoryController) {
    _categoryController = categoryController;
    return this;
  }

  // Getters
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String get error => _error;

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

  // Fetch all products
  Future<void> fetchProducts() async {
    _setLoading(true);
    _setError('');

    try {
      final snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      _products = snapshot.docs
          .map((doc) => ProductModel.fromSnapshot(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch products: $e');
      _setLoading(false);
    }
  }

  // Fetch products by category
  Future<List<ProductModel>> fetchProductsByCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.productsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      _setError('Failed to fetch products by category: $e');
      return [];
    }
  }

  // Upload product image to Firebase Storage
  Future<String?> uploadProductImage(File imageFile, String productName, int index) async {
    try {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_${productName.replaceAll(' ', '_').toLowerCase()}_$index.jpg';
      final storageRef = _storage.ref().child('product_images/$fileName');

      // Upload the file
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _setError('Failed to upload image: $e');
      return null;
    }
  }

  // Add a new product
  Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    double? discountPrice,
    required int quantity,
    required bool inStock,
    required String categoryId,
    required List<File> imageFiles,
    List<String>? tags,

    // Livestock fields
    String? breed,
    String? age,
    String? gender,
    double? weight,
    bool? isVaccinated,
    String? healthStatus,

    // Plant fields
    String? plantType,
    String? growthStage,
    String? careInstructions,
    String? harvestSeason,
    bool? isOrganic,

    // Common fields
    Map<String, dynamic>? specifications,
    Map<String, dynamic>? nutritionalInfo,
  }) async {
    _setLoading(true);
    _setError('');

    try {
      // Get category name
      final category = _categoryController.getCategoryById(categoryId);
      if (category == null) {
        _setError('Category not found');
        _setLoading(false);
        return false;
      }

      // Upload images if provided
      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        for (int i = 0; i < imageFiles.length; i++) {
          final uploadedUrl = await uploadProductImage(imageFiles[i], name, i);
          if (uploadedUrl != null) {
            imageUrls.add(uploadedUrl);
          }
        }
      }

      // Prepare data for Firestore - use FieldValue.serverTimestamp() here
      final data = {
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'inStock': inStock,
        'categoryId': categoryId,
        'categoryName': category.name,
        'imageUrls': imageUrls,
        'tags': tags ?? [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add optional fields only if they exist
      if (discountPrice != null) data['discountPrice'] = discountPrice;

      // Add livestock fields if provided
      if (breed != null) data['breed'] = breed;
      if (age != null) data['age'] = age;
      if (gender != null) data['gender'] = gender;
      if (weight != null) data['weight'] = weight;
      if (isVaccinated != null) data['isVaccinated'] = isVaccinated;
      if (healthStatus != null) data['healthStatus'] = healthStatus;

      // Add plant fields if provided
      if (plantType != null) data['plantType'] = plantType;
      if (growthStage != null) data['growthStage'] = growthStage;
      if (careInstructions != null) data['careInstructions'] = careInstructions;
      if (harvestSeason != null) data['harvestSeason'] = harvestSeason;
      if (isOrganic != null) data['isOrganic'] = isOrganic;

      // Add common fields if provided
      if (specifications != null) data['specifications'] = specifications;
      if (nutritionalInfo != null) data['nutritionalInfo'] = nutritionalInfo;

      // Add product to Firestore
      final docRef = await _firestore
          .collection(AppConstants.productsCollection)
          .add(data);

      // For adding to local list, use current timestamp
      final timestamp = Timestamp.now();
      final localData = Map<String, dynamic>.from(data);
      localData['createdAt'] = timestamp;
      localData['updatedAt'] = timestamp;

      // Add the new product to the list
      final newProduct = ProductModel.fromJson(localData, docRef.id);
      _products.add(newProduct);

      // Increment product count for the category
      await _categoryController.incrementProductCount(categoryId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add product: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update an existing product
  Future<bool> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    double? discountPrice,
    required int quantity,
    required bool inStock,
    required String categoryId,
    required String oldCategoryId,
    List<File>? newImageFiles,
    List<String>? existingImageUrls,
    List<String>? tags,

    // Livestock fields
    String? breed,
    String? age,
    String? gender,
    double? weight,
    bool? isVaccinated,
    String? healthStatus,

    // Plant fields
    String? plantType,
    String? growthStage,
    String? careInstructions,
    String? harvestSeason,
    bool? isOrganic,

    // Common fields
    Map<String, dynamic>? specifications,
    Map<String, dynamic>? nutritionalInfo,
  }) async {
    _setLoading(true);
    _setError('');

    try {
      // Get category name
      final category = _categoryController.getCategoryById(categoryId);
      if (category == null) {
        _setError('Category not found');
        _setLoading(false);
        return false;
      }

      // Prepare image URLs list
      List<String> imageUrls = existingImageUrls ?? [];

      // Upload new images if provided
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        for (int i = 0; i < newImageFiles.length; i++) {
          final uploadedUrl = await uploadProductImage(newImageFiles[i], name, imageUrls.length + i);
          if (uploadedUrl != null) {
            imageUrls.add(uploadedUrl);
          }
        }
      }

      // Prepare data for Firestore
      final data = {
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'inStock': inStock,
        'categoryId': categoryId,
        'categoryName': category.name,
        'imageUrls': imageUrls,
        'tags': tags ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add optional fields only if they exist
      if (discountPrice != null) data['discountPrice'] = discountPrice;

      // Add livestock fields if provided
      if (breed != null) data['breed'] = breed;
      if (age != null) data['age'] = age;
      if (gender != null) data['gender'] = gender;
      if (weight != null) data['weight'] = weight;
      if (isVaccinated != null) data['isVaccinated'] = isVaccinated;
      if (healthStatus != null) data['healthStatus'] = healthStatus;

      // Add plant fields if provided
      if (plantType != null) data['plantType'] = plantType;
      if (growthStage != null) data['growthStage'] = growthStage;
      if (careInstructions != null) data['careInstructions'] = careInstructions;
      if (harvestSeason != null) data['harvestSeason'] = harvestSeason;
      if (isOrganic != null) data['isOrganic'] = isOrganic;

      // Add common fields if provided
      if (specifications != null) data['specifications'] = specifications;
      if (nutritionalInfo != null) data['nutritionalInfo'] = nutritionalInfo;

      // Update product in Firestore
      await _firestore
          .collection(AppConstants.productsCollection)
          .doc(id)
          .update(data);

      // Update the product in the local list
      final index = _products.indexWhere((product) => product.id == id);
      if (index != -1) {
        final updatedProduct = _products[index].copyWith(
          name: name,
          description: description,
          price: price,
          discountPrice: discountPrice,
          quantity: quantity,
          inStock: inStock,
          categoryId: categoryId,
          categoryName: category.name,
          imageUrls: imageUrls,
          tags: tags,
          updatedAt: Timestamp.now(),
          breed: breed,
          age: age,
          gender: gender,
          weight: weight,
          isVaccinated: isVaccinated,
          healthStatus: healthStatus,
          plantType: plantType,
          growthStage: growthStage,
          careInstructions: careInstructions,
          harvestSeason: harvestSeason,
          isOrganic: isOrganic,
          specifications: specifications,
          nutritionalInfo: nutritionalInfo,
        );
        _products[index] = updatedProduct;
      }

      // Update category product counts if category changed
      if (categoryId != oldCategoryId) {
        await _categoryController.incrementProductCount(categoryId);
        await _categoryController.decrementProductCount(oldCategoryId);
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update product: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete a product
  Future<bool> deleteProduct(String id, String categoryId) async {
    _setLoading(true);
    _setError('');

    try {
      // Find product first to get the image URLs
      final productIndex = _products.indexWhere((product) => product.id == id);
      if (productIndex != -1) {
        final product = _products[productIndex];

        // Delete the product document
        await _firestore
          .collection(AppConstants.productsCollection)
          .doc(id)
          .delete();

        // Delete images from storage if they exist
        for (final imageUrl in product.imageUrls) {
          try {
            // Extract the file path from the URL
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print('Error deleting image: $e');
          }
        }

        // Remove the product from the list
        _products.removeAt(productIndex);

        // Decrement product count for the category
        await _categoryController.decrementProductCount(categoryId);
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete product: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get a single product by ID
  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search products
  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) {
      return _products;
    }

    final lowercaseQuery = query.toLowerCase();
    return _products.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
             product.description.toLowerCase().contains(lowercaseQuery) ||
             product.categoryName.toLowerCase().contains(lowercaseQuery) ||
             product.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Filter products by category
  List<ProductModel> filterByCategory(String categoryId) {
    if (categoryId.isEmpty) {
      return _products;
    }

    return _products.where((product) => product.categoryId == categoryId).toList();
  }

  // Filter products by type (livestock or plant)
  List<ProductModel> filterByType(String type) {
    switch (type) {
      case 'livestock':
        return _products.where((product) => product.isLivestock).toList();
      case 'plant':
        return _products.where((product) => product.isPlant).toList();
      default:
        return _products;
    }
  }

  // Sort products by different criteria
  List<ProductModel> sortProducts(String sortBy) {
    final sortedProducts = List<ProductModel>.from(_products);

    switch (sortBy) {
      case 'price_low_to_high':
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high_to_low':
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        sortedProducts.sort((a, b) =>
          (b.createdAt ?? Timestamp.now()).compareTo(a.createdAt ?? Timestamp.now()));
        break;
      case 'name':
        sortedProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      default: // Default is newest
        sortedProducts.sort((a, b) =>
          (b.createdAt ?? Timestamp.now()).compareTo(a.createdAt ?? Timestamp.now()));
    }

    return sortedProducts;
  }
}
