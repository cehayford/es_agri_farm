import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:provider/provider.dart';
import '../../../controllers/cart_controller.dart';
import '../../../models/product_model.dart';
import '../../../utils/app_theme.dart';
import '../cart/user_cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isAddingToCart = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // TODO: Navigate to cart
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images Carousel
            _buildImageCarousel(),

            // Product Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: AppTextStyles.heading2,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.product.categoryName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Price Information
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'GHS ${widget.product.price.toStringAsFixed(2)}',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.product.discountPrice != null && widget.product.discountPrice! > 0)
                            Text(
                              'GHS ${widget.product.discountPrice!.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Stock Status
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.product.inStock
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.product.inStock ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        color: widget.product.inStock
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description Section
                  const Text(
                    'Description',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: AppTextStyles.bodyMedium,
                  ),

                  const SizedBox(height: 24),

                  // Specifications Section (if any)
                  if (widget.product.specifications != null && widget.product.specifications!.isNotEmpty) ...[
                    const Text(
                      'Specifications',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    _buildSpecificationsTable(widget.product.specifications!),
                    const SizedBox(height: 24),
                  ],

                  // Product-specific Fields
                  _buildProductSpecificDetails(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImageCarousel() {
    if (widget.product.imageUrls.isEmpty) {
      // Display placeholder if no images
      return Container(
        height: 300,
        color: AppColors.lightGrey,
        child: const Center(
          child: Icon(Icons.image, size: 100, color: AppColors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Image Carousel
        FlutterCarousel(
          items: widget.product.imageUrls.map((imageUrl) {
            return Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.lightGrey,
                  child: const Center(
                    child: Icon(Icons.error, size: 50, color: AppColors.error),
                  ),
                );
              },
            );
          }).toList(),
          options: CarouselOptions(
            height: 300,
            viewportFraction: 1.0,
            enableInfiniteScroll: widget.product.imageUrls.length > 1,
            autoPlay: widget.product.imageUrls.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
        ),

        // Image Indicators
        if (widget.product.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.product.imageUrls.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? AppColors.primary
                        : AppColors.grey.withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSpecificationsTable(Map<String, dynamic> specifications) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: specifications.entries.map((entry) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: entry.key == specifications.keys.last
                      ? Colors.transparent
                      : AppColors.grey.withOpacity(0.3),
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value.toString(),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductSpecificDetails() {
    // Check if this is a livestock product
    if (widget.product.isLivestock) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Livestock Details',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 12),
          _buildDetailItem('Breed', widget.product.breed),
          _buildDetailItem('Age', widget.product.age),
          _buildDetailItem('Gender', widget.product.gender),
          _buildDetailItem('Weight', widget.product.weight != null
              ? '${widget.product.weight} kg'
              : null),
          _buildDetailItem('Vaccinated', widget.product.isVaccinated != null
              ? widget.product.isVaccinated! ? 'Yes' : 'No'
              : null),
          _buildDetailItem('Health Status', widget.product.healthStatus),
        ],
      );
    }

    // Check if this is a plant product
    if (widget.product.isPlant) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plant Details',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 12),
          _buildDetailItem('Plant Type', widget.product.plantType),
          _buildDetailItem('Growth Stage', widget.product.growthStage),
          _buildDetailItem('Care Instructions', widget.product.careInstructions),
          _buildDetailItem('Harvest Season', widget.product.harvestSeason),
          _buildDetailItem('Organic', widget.product.isOrganic != null
              ? widget.product.isOrganic! ? 'Yes' : 'No'
              : null),
        ],
      );
    }

    return const SizedBox.shrink(); // No specific details to show
  }

  Widget _buildDetailItem(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey.withAlpha(76)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildQuantityButton(
                    icon: Icons.remove,
                    onPressed: _quantity > 1 ? () {
                      setState(() {
                        _quantity--;
                      });
                    } : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_quantity',
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildQuantityButton(
                    icon: Icons.add,
                    onPressed: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Add to Cart Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.product.inStock && !_isAddingToCart ? () {
                  _addToCart();
                } : null,
                icon: _isAddingToCart
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.shopping_cart),
                label: Text(_isAddingToCart ? 'Adding...' : 'Add to Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: AppColors.grey.withAlpha(76),
                  disabledForegroundColor: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? AppColors.primary : AppColors.grey,
        ),
      ),
    );
  }

  // Add to cart functionality
  Future<void> _addToCart() async {
    if (!widget.product.inStock) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cartController = Provider.of<CartController>(context, listen: false);
      final success = await cartController.addToCart(widget.product, quantity: _quantity);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} added to cart'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserCartScreen()),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add to cart. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }
}
