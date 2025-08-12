import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/cart_controller.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/product_model.dart';
import '../../../utils/utils.dart';
import '../checkout/checkout_screen.dart'; // Import the checkout screen

class UserCartScreen extends StatefulWidget {
  const UserCartScreen({super.key});

  @override
  State<UserCartScreen> createState() => _UserCartScreenState();
}

class _UserCartScreenState extends State<UserCartScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch cart items when screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartController>(context, listen: false).fetchCartItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        automaticallyImplyLeading: false,
        actions: [
          Consumer<CartController>(
            builder: (context, cartController, _) {
              if (cartController.cartItems.isEmpty) return const SizedBox();

              return IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear cart',
                onPressed: () {
                  _showClearCartDialog(context);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<CartController>(
        builder: (context, cartController, _) {
          if (cartController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartController.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${cartController.error}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      cartController.fetchCartItems();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (cartController.cartItems.isEmpty) {
            return _buildEmptyCart();
          }

          return _buildCartContent(cartController);
        },
      ),
      bottomNavigationBar: Consumer<CartController>(
        builder: (context, cartController, _) {
          if (cartController.cartItems.isEmpty) {
            return const SizedBox.shrink(); // Return empty widget instead of null
          }
          return _buildCheckoutBar(cartController);
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.grey.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to shop screen or switch tab
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(CartController cartController) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cartController.cartItems.length,
            itemBuilder: (context, index) {
              final item = cartController.cartItems[index];
              return _buildCartItemCard(item, cartController);
            },
          ),
        ),
        _buildOrderSummary(cartController),
      ],
    );
  }

  Widget _buildCartItemCard(CartItemModel item, CartController cartController) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        cartController.removeFromCart(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} removed from cart'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                // Add back to cart
                cartController.addToCart(
                  ProductModel(
                    id: item.productId,
                    name: item.name,
                    description: '',
                    price: item.price,
                    quantity: 0,
                    inStock: true,
                    categoryId: item.categoryId,
                    categoryName: '',
                    imageUrls: [item.imageUrl],
                  ),
                  quantity: item.quantity,
                );
              },
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with product image, name and delete button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image with border and shadow
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 90,
                            height: 90,
                            color: AppColors.lightGrey,
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product name - with Expanded to allow wrapping
                            Expanded(
                              child: Text(
                                item.name,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                cartController.removeFromCart(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.name} removed from cart'),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      onPressed: () {
                                        // Add back to cart
                                        cartController.addToCart(
                                          ProductModel(
                                            id: item.productId,
                                            name: item.name,
                                            description: '',
                                            price: item.price,
                                            quantity: 0,
                                            inStock: true,
                                            categoryId: item.categoryId,
                                            categoryName: '',
                                            imageUrls: [item.imageUrl],
                                          ),
                                          quantity: item.quantity,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Unit price
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'GHS ${item.price.toStringAsFixed(2)} / unit',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom section with quantity controls and total price
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withAlpha(50),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // Quantity label
                  Text(
                    'Quantity:',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Quantity controls
                  _buildQuantityButton(
                    icon: Icons.remove,
                    onPressed: item.quantity > 1 ? () {
                      cartController.updateQuantity(item.id, item.quantity - 1);
                    } : null,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.grey.withAlpha(76)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildQuantityButton(
                    icon: Icons.add,
                    onPressed: () {
                      cartController.updateQuantity(item.id, item.quantity + 1);
                    },
                  ),

                  const Spacer(),

                  // Total price (right-aligned)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total:',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'GHS ${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onPressed, // Changed to accept nullable callback
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null
            ? AppColors.primary.withAlpha(20)
            : Colors.grey.withAlpha(30), // Dimmed color when disabled
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        icon: Icon(
          icon,
          size: 18,
          color: onPressed != null ? AppColors.primary : Colors.grey, // Grey when disabled
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildOrderSummary(CartController cartController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', cartController.subtotal),
          _buildSummaryRow('Delivery Fee', cartController.deliveryFee),
          const Divider(height: 24),
          _buildSummaryRow('Total', cartController.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                : AppTextStyles.bodyMedium,
          ),
          Text(
            'GHS ${amount.toStringAsFixed(2)}',
            style: isTotal
                ? AppTextStyles.heading3.copyWith(color: AppColors.primary)
                : AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(CartController cartController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to checkout screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CheckoutScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Proceed to Checkout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<CartController>(context, listen: false).clearCart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cart'),
          ),
        ],
      ),
    );
  }
}
