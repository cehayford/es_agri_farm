import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';

class CategoryController with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<CategoryModel> get categories => _categories;
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

  // Fetch all categories
  Future<void> fetchCategories() async {
    _setLoading(true);
    _setError('');

    try {
      final snapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .orderBy('name')
          .get();

      _categories = snapshot.docs
          .map((doc) => CategoryModel.fromSnapshot(doc))
          .toList();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to fetch categories: $e');
      _setLoading(false);
    }
  }

  // Upload image to Firebase Storage
  Future<String?> uploadCategoryImage(File imageFile, String categoryName) async {
    try {
      final fileName = 'category_${DateTime.now().millisecondsSinceEpoch}_${categoryName.replaceAll(' ', '_').toLowerCase()}.jpg';
      final storageRef = _storage.ref().child('category_images/$fileName');

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

  // Add a new category
  Future<bool> addCategory({
    required String name,
    required String description,
    File? imageFile,
  }) async {
    _setLoading(true);
    _setError('');

    try {
      // Upload image if provided
      String imageUrl = '';
      if (imageFile != null) {
        final uploadedUrl = await uploadCategoryImage(imageFile, name);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      // Prepare data for Firestore - use FieldValue.serverTimestamp() here
      final data = {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'productCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(AppConstants.categoriesCollection)
          .add(data);

      // For adding to local list, use current timestamp
      final timestamp = Timestamp.now();
      final localData = {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'productCount': 0,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      };

      // Add the new category to the list
      final newCategory = CategoryModel.fromJson(localData, docRef.id);
      _categories.add(newCategory);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add category: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update an existing category
  Future<bool> updateCategory({
    required String id,
    required String name,
    required String description,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    _setLoading(true);
    _setError('');

    try {
      // Start with existing image URL
      String imageUrl = existingImageUrl ?? '';

      // Upload new image if provided
      if (imageFile != null) {
        final uploadedUrl = await uploadCategoryImage(imageFile, name);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      // Prepare data for Firestore - use FieldValue.serverTimestamp() here
      final data = {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(id)
          .update(data);

      // Update the category in the list
      final index = _categories.indexWhere((category) => category.id == id);
      if (index != -1) {
        final updatedCategory = _categories[index].copyWith(
          name: name,
          description: description,
          imageUrl: imageUrl,
          updatedAt: Timestamp.now(),
        );
        _categories[index] = updatedCategory;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update category: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete a category
  Future<bool> deleteCategory(String id) async {
    _setLoading(true);
    _setError('');

    try {
      // Find category first to get the image URL
      final categoryIndex = _categories.indexWhere((category) => category.id == id);
      if (categoryIndex != -1) {
        final category = _categories[categoryIndex];

        // Delete the category document
        await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(id)
          .delete();

        // Delete image from storage if it exists
        if (category.imageUrl.isNotEmpty) {
          try {
            // Extract the file path from the URL
            final ref = _storage.refFromURL(category.imageUrl);
            await ref.delete();
          } catch (e) {
            print('Error deleting image: $e');
          }
        }

        // Remove the category from the list
        _categories.removeAt(categoryIndex);
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete category: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get a single category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Increment product count for a category
  Future<bool> incrementProductCount(String categoryId) async {
    try {
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .update({
        'productCount': FieldValue.increment(1),
      });

      // Update local state
      final index = _categories.indexWhere((cat) => cat.id == categoryId);
      if (index != -1) {
        final category = _categories[index];
        _categories[index] = category.copyWith(
          productCount: category.productCount + 1,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update product count: $e');
      return false;
    }
  }

  // Decrement product count for a category
  Future<bool> decrementProductCount(String categoryId) async {
    try {
      await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .update({
        'productCount': FieldValue.increment(-1),
      });

      // Update local state
      final index = _categories.indexWhere((cat) => cat.id == categoryId);
      if (index != -1) {
        final category = _categories[index];
        _categories[index] = category.copyWith(
          productCount: category.productCount - 1 < 0 ? 0 : category.productCount - 1,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update product count: $e');
      return false;
    }
  }
}
