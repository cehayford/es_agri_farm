import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controllers/category_controller.dart';
import '../../../models/category_model.dart';
import '../../../utils/utils.dart';
import '../../../widgets/widgets.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to schedule the loading after the build is complete
    Future.microtask(() => _loadCategories());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categoryController = Provider.of<CategoryController>(context, listen: false);
    await categoryController.fetchCategories();
  }

  List<CategoryModel> _getFilteredCategories(List<CategoryModel> categories) {
    if (_searchQuery.isEmpty) {
      return categories;
    }

    final query = _searchQuery.toLowerCase();
    return categories.where((category) {
      return category.name.toLowerCase().contains(query) ||
             category.description.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryController>(
      builder: (context, categoryController, _) {
        final categories = categoryController.categories;
        final filteredCategories = _getFilteredCategories(categories);

        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search categories...',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  )
                : const Text('Categories'),
            automaticallyImplyLeading: false,
            actions: [
              // Search toggle
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    _searchQuery = '';
                  });
                },
              ),
              // Refresh
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCategories,
              ),
            ],
          ),
          body: categoryController.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredCategories.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadCategories,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = filteredCategories[index];
                          return _buildCategoryItem(category);
                        },
                      ),
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCategoryDialog(),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Categories Found',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create categories to organize your products',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: category.imageUrl.isNotEmpty
                        ? Image.network(
                            category.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.lightGrey,
                                child: const Icon(Icons.image_not_supported, color: AppColors.grey),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.category, color: AppColors.primary, size: 32),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Category details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTextStyles.heading3,
                      ),
                      if (category.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Product count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${category.productCount} ${category.productCount == 1 ? 'product' : 'products'}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit button
                TextButton.icon(
                  onPressed: () => _showCategoryDialog(category: category),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),

                // Delete button
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(category),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryDialog({CategoryModel? category}) async {
    // Reset form data and selected image
    _nameController.text = category?.name ?? '';
    _descriptionController.text = category?.description ?? '';
    _selectedImage = null;
    bool _isImageUploading = false;
    bool _isSaving = false;

    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during operations
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(category == null ? 'Add Category' : 'Edit Category'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'Enter category name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a category name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Enter category description',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Image selection
                    const Text(
                      'Category Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Center(
                      child: GestureDetector(
                        onTap: _isImageUploading || _isSaving
                            ? null
                            : () async {
                                setState(() {
                                  _isImageUploading = true;
                                });

                                await _pickImage();

                                // Update the dialog state to show the new image
                                setState(() {
                                  _isImageUploading = false;
                                });
                              },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.grey.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: _isImageUploading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _selectedImage != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : category?.imageUrl != null && category!.imageUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                category.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Center(
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      size: 50,
                                                      color: AppColors.grey,
                                                    ),
                                                  );
                                                },
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 50,
                                                  color: AppColors.grey,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Tap to select image',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                            ),
                            if (_isImageUploading)
                              Positioned(
                                bottom: 8,
                                child: Text(
                                  'Uploading image...',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : () {
                  Navigator.pop(context);
                  _selectedImage = null; // Reset selected image
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isImageUploading || _isSaving
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isSaving = true;
                          });

                          final categoryController = Provider.of<CategoryController>(
                            context,
                            listen: false,
                          );

                          bool success;
                          if (category == null) {
                            // Add new category
                            success = await categoryController.addCategory(
                              name: _nameController.text.trim(),
                              description: _descriptionController.text.trim(),
                              imageFile: _selectedImage,
                            );
                          } else {
                            // Update existing category
                            success = await categoryController.updateCategory(
                              id: category.id,
                              name: _nameController.text.trim(),
                              description: _descriptionController.text.trim(),
                              imageFile: _selectedImage,
                              existingImageUrl: category.imageUrl,
                            );
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            _selectedImage = null; // Reset selected image

                            // Show success/error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Category ${category == null ? 'added' : 'updated'} successfully!'
                                      : 'Failed to ${category == null ? 'add' : 'update'} category: ${categoryController.error}',
                                ),
                                backgroundColor: success ? AppColors.success : AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: _isSaving
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(category == null ? 'Adding...' : 'Updating...'),
                        ],
                      )
                    : Text(category == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(CategoryModel category) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? ' +
          (category.productCount > 0
              ? 'This category contains ${category.productCount} products that may be affected.'
              : ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final categoryController = Provider.of<CategoryController>(
                context,
                listen: false,
              );

              final success = await categoryController.deleteCategory(category.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Category deleted successfully!'
                          : 'Failed to delete category: ${categoryController.error}',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
