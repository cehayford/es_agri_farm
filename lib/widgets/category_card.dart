import 'package:flutter/material.dart';
import '../utils/utils.dart';

class CategoryCard extends StatelessWidget {
  final String categoryName;
  final String categoryImage;
  final int productCount;
  final VoidCallback? onTap;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.categoryName,
    required this.categoryImage,
    this.productCount = 0,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(
          minWidth: 80,
          maxWidth: 120, // Prevent excessive width
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Allow flexible height
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.white : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: categoryImage.isEmpty
                    ? Icon(
                        Icons.category,
                        size: 30,
                        color: isSelected ? AppColors.primary : AppColors.grey,
                      )
                    : Image.network(
                        categoryImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.category,
                            size: 30,
                            color: isSelected ? AppColors.primary : AppColors.grey,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                categoryName,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (productCount > 0) ...[
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  '$productCount items',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: isSelected
                        ? AppColors.white.withOpacity(0.8)
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HorizontalCategoryList extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedCategory;
  final Function(String)? onCategorySelected;

  const HorizontalCategoryList({
    super.key,
    required this.categories,
    this.selectedCategory,
    this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: null, // Remove fixed height
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: IntrinsicHeight( // Ensure all cards have same height
          child: Row(
            children: categories.map((category) {
              final isSelected = selectedCategory == category['name'];

              return CategoryCard(
                categoryName: category['name'] ?? '',
                categoryImage: category['image'] ?? '',
                productCount: category['count'] ?? 0,
                isSelected: isSelected,
                onTap: () {
                  if (onCategorySelected != null) {
                    onCategorySelected!(category['name'] ?? '');
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
