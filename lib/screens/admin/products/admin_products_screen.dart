import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/category_controller.dart';
import '../../../models/product_model.dart';
import '../../../utils/utils.dart';
import '../../../widgets/widgets.dart';
import 'admin_product_detail_screen.dart';
import 'admin_product_form_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedCategory = '';
  String _sortBy = 'newest';
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to schedule loading after the initial build
    Future.microtask(() => _loadProducts());
  }

  Future<void> _loadProducts() async {
    final productController = Provider.of<ProductController>(context, listen: false);
    final categoryController = Provider.of<CategoryController>(context, listen: false);

    // Ensure categories are loaded first
    if (categoryController.categories.isEmpty) {
      await categoryController.fetchCategories();
    }

    await productController.fetchProducts();
  }

  List<ProductModel> _getFilteredProducts(ProductController productController) {
    List<ProductModel> filteredProducts = productController.products;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredProducts = productController.searchProducts(_searchQuery);
    }

    // Apply category filter
    if (_selectedCategory.isNotEmpty) {
      filteredProducts = filteredProducts.where(
        (product) => product.categoryId == _selectedCategory
      ).toList();
    }

    // Apply type filter
    if (_filterType != 'all') {
      filteredProducts = productController.filterByType(_filterType);
    }

    // Apply sorting
    switch (_sortBy) {
      case 'price_low_to_high':
        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high_to_low':
        filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        filteredProducts.sort((a, b) =>
          (b.createdAt ?? Timestamp.now()).compareTo(a.createdAt ?? Timestamp.now()));
        break;
      case 'name':
        filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return filteredProducts;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductController, CategoryController>(
      builder: (context, productController, categoryController, _) {
        final filteredProducts = _getFilteredProducts(productController);

        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  )
                : const Text('Products'),
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
                onPressed: _loadProducts,
              ),
              // Filter menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  if (value.startsWith('sort_')) {
                    setState(() {
                      _sortBy = value.replaceFirst('sort_', '');
                    });
                  } else if (value.startsWith('type_')) {
                    setState(() {
                      _filterType = value.replaceFirst('type_', '');
                    });
                  } else if (value.startsWith('category_')) {
                    setState(() {
                      _selectedCategory = value.replaceFirst('category_', '');
                    });
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: '',
                    enabled: false,
                    child: Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  CheckedPopupMenuItem(
                    value: 'sort_newest',
                    checked: _sortBy == 'newest',
                    child: const Text('Newest First'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'sort_name',
                    checked: _sortBy == 'name',
                    child: const Text('Name (A-Z)'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'sort_price_low_to_high',
                    checked: _sortBy == 'price_low_to_high',
                    child: const Text('Price: Low to High'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'sort_price_high_to_low',
                    checked: _sortBy == 'price_high_to_low',
                    child: const Text('Price: High to Low'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: '',
                    enabled: false,
                    child: Text('Filter By Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  CheckedPopupMenuItem(
                    value: 'type_all',
                    checked: _filterType == 'all',
                    child: const Text('All Products'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'type_livestock',
                    checked: _filterType == 'livestock',
                    child: const Text('Livestock Only'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'type_plant',
                    checked: _filterType == 'plant',
                    child: const Text('Plants Only'),
                  ),
                  if (categoryController.categories.isNotEmpty) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: '',
                      enabled: false,
                      child: Text('Filter By Category', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    CheckedPopupMenuItem(
                      value: 'category_',
                      checked: _selectedCategory.isEmpty,
                      child: const Text('All Categories'),
                    ),
                    ...categoryController.categories.map((category) =>
                      CheckedPopupMenuItem(
                        value: 'category_${category.id}',
                        checked: _selectedCategory == category.id,
                        child: Text(category.name),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          body: productController.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductItem(product, productController);
                        },
                      ),
                    ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProductFormScreen(),
                ),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = 'No products found';
    if (_searchQuery.isNotEmpty) {
      message = 'No products match your search';
    } else if (_selectedCategory.isNotEmpty) {
      message = 'No products in this category';
    } else if (_filterType != 'all') {
      message = 'No ${_filterType == 'livestock' ? 'livestock' : 'plant'} products available';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add products to your inventory',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProductFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(ProductModel product, ProductController productController) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminProductDetailScreen(productId: product.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: product.imageUrls.isNotEmpty
                          ? Image.network(
                              product.imageUrls.first,
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
                              color: AppColors.lightGrey,
                              child: const Icon(Icons.inventory_2, color: AppColors.grey, size: 50),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          product.name,
                          style: AppTextStyles.heading3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Product category
                        Chip(
                          label: Text(
                            product.categoryName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: AppColors.lightGrey,
                          visualDensity: VisualDensity.compact,
                        ),

                        // Product price
                        Row(
                          children: [
                            Text(
                              'GHS ${product.price.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: product.discountPrice != null
                                    ? AppColors.grey
                                    : AppColors.primary,
                                decoration: product.discountPrice != null
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (product.discountPrice != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                'GHS ${product.discountPrice!.toStringAsFixed(2)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${product.discountPercentage}%',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Stock status
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: product.inStock
                                    ? AppColors.success.withOpacity(0.2)
                                    : AppColors.error.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.inStock ? 'In Stock' : 'Out of Stock',
                                style: TextStyle(
                                  color: product.inStock ? AppColors.success : AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Qty: ${product.quantity}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        // Product type indicator
                        if (product.isLivestock || product.isPlant)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (product.isLivestock
                                  ? Colors.orange
                                  : Colors.green).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.isLivestock ? 'Livestock' : 'Plant',
                              style: TextStyle(
                                color: product.isLivestock ? Colors.orange : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // View button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminProductDetailScreen(productId: product.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Edit button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminProductFormScreen(productId: product.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Delete button
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(product, productController),
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
      ),
    );
  }

  Future<void> _showDeleteConfirmation(ProductModel product, ProductController productController) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await productController.deleteProduct(
                product.id,
                product.categoryId,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Product deleted successfully!'
                          : 'Failed to delete product: ${productController.error}',
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
