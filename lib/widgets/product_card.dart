import 'package:flutter/material.dart';
import '../screens/user/product/product_details_screen.dart';
import '../utils/utils.dart';
import '../models/product_model.dart';// Import the product details screen

class ProductCard extends StatelessWidget {
  final String productName;
  final String productImage;
  final double price;
  final double? originalPrice;
  final bool isInStock;
  final VoidCallback? onTap;
  final ProductModel product; // Add product model for navigation

  const ProductCard({
    super.key,
    required this.productName,
    required this.productImage,
    required this.price,
    this.originalPrice,
    this.isInStock = true,
    this.onTap,
    required this.product, // Required for details page
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        // Navigate to product details when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        clipBehavior: Clip.antiAlias, // This will clip any overflowing content
        child: SizedBox(
          // Increase the fixed height to accommodate all content

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image - fixed height to prevent overflow
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Stack(
                  children: [
                    // Image container
                    Positioned.fill(
                      child: productImage.isEmpty
                          ? Container(
                              color: AppColors.lightGrey,
                              child: const Icon(Icons.image, size: 50, color: AppColors.grey),
                            )
                          : Image.network(
                              productImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.lightGrey,
                                  child: const Icon(Icons.image, size: 50, color: AppColors.grey),
                                );
                              },
                            ),
                    ),

                    // Stock Status
                    if (!isInStock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Out of Stock',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Discount Badge
                    if (originalPrice != null && originalPrice! > price)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${(((originalPrice! - price) / originalPrice!) * 100).round()}% OFF',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Details - use Expanded to take remaining space
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product Name
                      Text(
                        productName,
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Price row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'GHS ${price.toStringAsFixed(2)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (originalPrice != null) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'GHS ${originalPrice!.toStringAsFixed(2)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.grey,
                                  fontSize: 10, // Make original price smaller
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Stock Status (smaller text)
                      Text(
                        isInStock ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 10,
                          color: isInStock ? AppColors.success : AppColors.error,
                        ),
                      ),

                      // Spacer to push buttons to bottom
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
