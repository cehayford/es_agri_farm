import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/category_controller.dart';
import '../../../models/product_model.dart';
import '../../../models/category_model.dart';
import '../../../utils/utils.dart';
import '../../../widgets/product_card.dart';

class UserShopScreen extends StatefulWidget {
  const UserShopScreen({super.key});

  @override
  State<UserShopScreen> createState() => _UserShopScreenState();
}

class _UserShopScreenState extends State<UserShopScreen> {
  String _selectedCategory = '';
  String _selectedSortOption = 'newest';
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to run after the first build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final productController = Provider.of<ProductController>(context, listen: false);
    final categoryController = Provider.of<CategoryController>(context, listen: false);

    await Future.wait([
      productController.fetchProducts(),
      categoryController.fetchCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // Search bar if needed
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Search results for: "$_searchQuery"',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Categories horizontal list
            _buildCategoriesList(),

            // Sort options
            _buildSortOptions(),

            // Products list/grid
            Expanded(
              child: _buildProductsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    return Consumer<CategoryController>(
      builder: (context, categoryController, _) {
        if (categoryController.isLoading) {
          return const Center(child: LinearProgressIndicator());
        }

        if (categoryController.categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categoryController.categories.length + 1, // +1 for "All" category
            itemBuilder: (context, index) {
              // First item is "All Categories"
              if (index == 0) {
                return _buildCategoryItem(
                  null,
                  isSelected: _selectedCategory.isEmpty,
                );
              }

              // Actual categories
              final category = categoryController.categories[index - 1];
              return _buildCategoryItem(
                category,
                isSelected: _selectedCategory == category.id,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryItem(CategoryModel? category, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category?.id ?? '';
        });
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(25) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category image or placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary.withAlpha(50) : Colors.grey.shade100,
              ),
              child: category == null || category.imageUrl.isEmpty
                  ? Icon(
                      Icons.category,
                      color: isSelected ? AppColors.primary : Colors.grey,
                      size: 32,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        category.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.category,
                            color: isSelected ? AppColors.primary : Colors.grey,
                            size: 32,
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            // Category name
            Text(
              category?.name ?? 'All',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // Changed from withOpacity to withAlpha
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(),
          labelText: 'Sort By',
        ),
        value: _selectedSortOption,
        items: const [
          DropdownMenuItem<String>(
            value: 'newest',
            child: Text('Newest'),
          ),
          DropdownMenuItem<String>(
            value: 'price_low_to_high',
            child: Text('Price: Low to High'),
          ),
          DropdownMenuItem<String>(
            value: 'price_high_to_low',
            child: Text('Price: High to Low'),
          ),
          DropdownMenuItem<String>(
            value: 'name',
            child: Text('Name'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedSortOption = value ?? 'newest';
          });
        },
      ),
    );
  }

  Widget _buildProductsList() {
    return Consumer<ProductController>(
      builder: (context, productController, _) {
        if (productController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productController.error.isNotEmpty) {
          return Center(
            child: Text(
              'Error: ${productController.error}',
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        // Apply filters: category and search
        List<ProductModel> filteredProducts = productController.products;

        // Filter by category if selected
        if (_selectedCategory.isNotEmpty) {
          filteredProducts = filteredProducts
              .where((product) => product.categoryId == _selectedCategory)
              .toList();
        }

        // Filter by search query if present
        if (_searchQuery.isNotEmpty) {
          filteredProducts = filteredProducts
              .where((product) =>
                product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                product.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        // Sort products based on selected option
        filteredProducts = _sortProducts(filteredProducts, _selectedSortOption);

        if (filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No products matching "$_searchQuery"'
                      : _selectedCategory.isNotEmpty
                          ? 'No products in this category'
                          : 'No products available',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (_searchQuery.isNotEmpty || _selectedCategory.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = '';
                        _searchController.clear();
                      });
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          );
        }

        // Display products in grid or list view
        if (_isGridView) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return ProductCard(
                product: product,
                productName: product.name,
                productImage: product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
                price: product.price,
                originalPrice: product.discountPrice != null ? product.price : null,
                isInStock: product.inStock,
              );
            },
          );
        } else {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredProducts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return ProductCard(
                product: product,
                productName: product.name,
                productImage: product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
                price: product.price,
                originalPrice: product.discountPrice != null ? product.price : null,
                isInStock: product.inStock,
              );
            },
          );
        }
      },
    );
  }

  // Helper method for sorting products
  List<ProductModel> _sortProducts(List<ProductModel> products, String sortOption) {
    final sortedProducts = List<ProductModel>.from(products);

    switch (sortOption) {
      case 'newest':
        sortedProducts.sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;

      case 'price_low_to_high':
        sortedProducts.sort((a, b) =>
          (a.discountPrice ?? a.price).compareTo(b.discountPrice ?? b.price));
        break;

      case 'price_high_to_low':
        sortedProducts.sort((a, b) =>
          (b.discountPrice ?? b.price).compareTo(a.discountPrice ?? a.price));
        break;

      case 'name':
        sortedProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return sortedProducts;
  }

  // Search dialog
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Products'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter product name, description...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
