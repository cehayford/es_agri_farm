import 'controller/productor_controller.dart';

class ProductSearchFilter {
  // Filter by category and max price
  static List<Product> filterProducts({
    required List<Product> products,
    String category = 'All',
    double? maxPrice,
  }) {
    return products.where((product) {
      final matchesCategory = category == 'All' ||
          ((product.category.toLowerCase() == category.toLowerCase()));
      final matchesPrice = maxPrice == null || product.price <= maxPrice;
      return matchesCategory && matchesPrice;
    }).toList();
  }

  // Search by name or price
  static List<Product> searchProducts({
    required List<Product> products,
    required String query,
  }) {
    final lowerQuery = query.toLowerCase();
    return products.where((product) {
      final nameMatch = product.name.toLowerCase().contains(lowerQuery);
      final priceMatch =
          product.price.toString().toLowerCase().contains(lowerQuery);
      return nameMatch || priceMatch;
    }).toList();
  }
}
