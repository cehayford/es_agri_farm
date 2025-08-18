import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/product_controller.dart';
import '../../../models/product_model.dart';
import '../../../utils/utils.dart';
import 'admin_product_form_screen.dart';

class AdminProductDetailScreen extends StatelessWidget {
  final String productId;

  const AdminProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductController>(
      builder: (context, productController, _) {
        final product = productController.getProductById(productId);

        if (product == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Product Details'),
            ),
            body: const Center(
              child: Text('Product not found'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Product Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProductFormScreen(productId: productId),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product images carousel
                _buildImageCarousel(product),
                const SizedBox(height: 24),

                // Basic product info
                _buildBasicInfo(product),
                const SizedBox(height: 24),

                // Divider
                const Divider(),
                const SizedBox(height: 16),

                // Product description
                const Text(
                  'Description',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Specific product type details
                if (product.isLivestock) _buildLivestockDetails(product),
                if (product.isPlant) _buildPlantDetails(product),

                // Specifications if available
                if (product.specifications != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildSpecifications(product),
                ],

                // Nutritional info if available
                if (product.nutritionalInfo != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildNutritionalInfo(product),
                ],

                // Tags
                if (product.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Tags',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.tags.map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: AppColors.lightGrey,
                    )).toList(),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCarousel(ProductModel product) {
    if (product.imageUrls.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 50,
            color: AppColors.grey,
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: product.imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.lightGrey,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: AppColors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfo(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name
        Text(
          product.name,
          style: AppTextStyles.heading1,
        ),
        const SizedBox(height: 8),

        // Category
        Row(
          children: [
            const Icon(
              Icons.category,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Category: ${product.categoryName}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Price and discount
        Row(
          children: [
            Text(
              'GHS ${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: product.discountPrice != null ? TextDecoration.lineThrough : null,
                color: product.discountPrice != null ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
            if (product.discountPrice != null) ...[
              const SizedBox(width: 12),
              Text(
                'GHS ${product.discountPrice!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${product.discountPercentage}% OFF',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Stock information
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Quantity: ${product.quantity}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),

        // Product type indicator
        if (product.isLivestock || product.isPlant) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (product.isLivestock
                  ? Colors.orange
                  : Colors.green).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              product.isLivestock ? 'Livestock Product' : 'Plant Product',
              style: TextStyle(
                color: product.isLivestock ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLivestockDetails(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Livestock Details',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 16),

        if (product.breed != null)
          _buildDetailItem('Breed', product.breed!),
        if (product.age != null)
          _buildDetailItem('Age', product.age!),
        if (product.gender != null)
          _buildDetailItem('Gender', product.gender!),
        if (product.weight != null)
          _buildDetailItem('Weight', '${product.weight} kg'),
        if (product.isVaccinated != null)
          _buildDetailItem('Vaccinated', product.isVaccinated! ? 'Yes' : 'No'),
        if (product.healthStatus != null)
          _buildDetailItem('Health Status', product.healthStatus!),
      ],
    );
  }

  Widget _buildPlantDetails(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Plant Details',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 16),

        if (product.plantType != null)
          _buildDetailItem('Plant Type', product.plantType!),
        if (product.growthStage != null)
          _buildDetailItem('Growth Stage', product.growthStage!),
        if (product.harvestSeason != null)
          _buildDetailItem('Harvest Season', product.harvestSeason!),
        if (product.isOrganic != null)
          _buildDetailItem('Organic', product.isOrganic! ? 'Yes' : 'No'),
        if (product.careInstructions != null)
          _buildDetailItem('Care Instructions', product.careInstructions!),
      ],
    );
  }

  Widget _buildSpecifications(ProductModel product) {
    if (product.specifications == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specifications',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 16),

        ...product.specifications!.entries.map((entry) =>
          _buildDetailItem(entry.key, entry.value.toString())
        ).toList(),
      ],
    );
  }

  Widget _buildNutritionalInfo(ProductModel product) {
    if (product.nutritionalInfo == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutritional Information',
          style: AppTextStyles.heading3,
        ),
        const SizedBox(height: 16),

        ...product.nutritionalInfo!.entries.map((entry) =>
          _buildDetailItem(entry.key, entry.value.toString())
        ).toList(),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
