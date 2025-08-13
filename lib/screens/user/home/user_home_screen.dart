import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:provider/provider.dart';
import '../../../controllers/product_controller.dart';
import '../../../models/product_model.dart';
import '../../../utils/utils.dart';
import '../../../widgets/product_card.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentCarouselIndex = 0;
  final List<String> _carouselImages = [
    'assets/images/slide1.jpg',
    'assets/images/slide2.jpg',
    'assets/images/slide3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to run after the first build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    final productController = Provider.of<ProductController>(context, listen: false);
    await productController.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri Farm'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16,),
              // Carousel Slider
              _buildCarouselSlider(),

              const SizedBox(height: 16),

              // Featured Products Section
              _buildSectionHeader('Featured Products'),

              // Products Grid
              _buildProductsGrid(),


              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return Column(
      children: [
        FlutterCarousel(
          items: _carouselImages.map((imageUrl) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,

                ),
              ),
            );
          }).toList(),
          options: CarouselOptions(
            height: 180,
            viewportFraction: 0.95,
            initialPage: 0,
            enableInfiniteScroll: true,
            reverse: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            scrollDirection: Axis.horizontal,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3,
          ),
          TextButton(
            onPressed: () {
              // Navigate to see all products/categories
            },
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
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

        final products = productController.products;

        if (products.isEmpty) {
          return const Center(
            child: Text('No products available'),
          );
        }

        // Limit to 20 products as requested
        final limitedProducts = products.take(20).toList();

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: limitedProducts.length,
            itemBuilder: (context, index) {
              final product = limitedProducts[index];
              return _buildProductCard(product);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return ProductCard(
      productName: product.name,
      productImage: product.imageUrls.isNotEmpty
          ? product.imageUrls[0]
          : 'assets/images/product_placeholder.svg',
      price: product.price,
      originalPrice: product.discountPrice != null && product.discountPrice! > 0
          ? product.price
          : null,
      isInStock: product.inStock,
      product: product, // Pass the full product object for details navigation
    );
  }

  Widget _buildCategoryItem(String name, IconData icon) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentProducts() {
    return Consumer<ProductController>(
      builder: (context, productController, _) {
        if (productController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = productController.products;

        if (products.isEmpty) {
          return const Center(
            child: Text('No products available'),
          );
        }

        // Get the most recent products (up to 10)
        final recentProducts = products.take(10).toList();

        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recentProducts.length,
            itemBuilder: (context, index) {
              final product = recentProducts[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                child: _buildProductCard(product),
              );
            },
          ),
        );
      },
    );
  }
}
