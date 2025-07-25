import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'controller/productor_controller.dart';
import 'controller/CartController.dart'; // Import your cart controller

const Color kPrimaryColor = Color(0xFF85CB33);
const Color kAccentColor = Color(0xFF000000);
const Color kBackgroundColor = Color(0xFFEFFFC8);

class ProductListScreen extends StatefulWidget {
  final CartController cartController;
  const ProductListScreen({super.key, required this.cartController});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  int _selectedIndex = 0; // Home is index 0

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      // Already on home
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/category');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ProductController();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title:
            const Text('Farm Products', style: TextStyle(color: kAccentColor)),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.logout, color: kAccentColor),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: controller.fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No farm produce available.'));
          }
          final products = snapshot.data!;

          // Get unique categories
          final categories = [
            'All',
            ...{for (var p in products) p.category}
          ];

          // Filter products by category only
          List<Product> filteredProducts = products.where((product) {
            return selectedCategory == 'All' ||
                product.category.toLowerCase() ==
                    selectedCategory.toLowerCase();
          }).toList();

          // Further filter by search query
          final filtered = filteredProducts
              .where((product) =>
                  product.name
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()) ||
                  product.price.toString().contains(searchQuery))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedCategory,
                      items: categories
                          .map((cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search products',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Product image
                          Expanded(
                            child: product.imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      product.imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.broken_image,
                                                  color: Colors.grey, size: 48),
                                    ),
                                  )
                                : const Icon(Icons.agriculture,
                                    color: kPrimaryColor, size: 48),
                          ),
                          const SizedBox(height: 8),
                          // Product title
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: kAccentColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Product description
                          Text(
                            product.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Price
                          Text(
                            '₵${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: kAccentColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Buy now button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Add to Cart'),
                            onPressed: () {
                              widget.cartController.addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('${product.name} added to cart!')),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Category',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
