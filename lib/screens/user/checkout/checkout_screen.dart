import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/order_controller.dart';
import '../../../controllers/shipping_controller.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/order_model.dart';
import '../../../models/shipping_address_model.dart';
import '../../../utils/app_theme.dart';
import '../orders/order_details_screen.dart';
import 'add_shipping_address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;

  // Calculate order totals
  double _calculateSubtotal(List<CartItemModel> items) {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  double _calculateShippingFee() {
    // Fixed shipping fee for simplicity
    return 5.0;
  }

  double _calculateTax(double subtotal) {
    // 5% tax for example
    return subtotal * 0.05;
  }

  double _calculateTotal(double subtotal, double shippingFee, double tax) {
    return subtotal + shippingFee + tax;
  }

  // Convert cart items to order items
  List<OrderItemModel> _cartToOrderItems(List<CartItemModel> cartItems) {
    return cartItems.map((item) => OrderItemModel(
      productId: item.productId,
      productName: item.name,
      productImage: item.imageUrl,
      price: item.price,
      quantity: item.quantity,
    )).toList();
  }

  // Place order
  Future<void> _placeOrder() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final cartController = Provider.of<CartController>(context, listen: false);
    final shippingController = Provider.of<ShippingController>(context, listen: false);
    final orderController = Provider.of<OrderController>(context, listen: false);

    if (shippingController.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shipping address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (cartController.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate order totals
      final cartItems = cartController.cartItems;
      final subtotal = _calculateSubtotal(cartItems);
      final shippingFee = _calculateShippingFee();
      final tax = _calculateTax(subtotal);
      final total = _calculateTotal(subtotal, shippingFee, tax);

      // Create order
      final order = await orderController.createOrder(
        userId: authController.user!.id,
        items: _cartToOrderItems(cartItems),
        subtotal: subtotal,
        shippingFee: shippingFee,
        tax: tax,
        total: total,
        shippingAddress: shippingController.selectedAddress!,
      );

      if (order != null) {
        // Clear cart
        await cartController.clearCart();

        // Show success message and navigate to order details
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to order details screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(orderId: order.id),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderController.error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Load shipping addresses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      final shippingController = Provider.of<ShippingController>(context, listen: false);
      shippingController.fetchAddresses(authController.user!.id);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Provider.of<CartController>(context);
    final shippingController = Provider.of<ShippingController>(context);

    // Calculate order totals
    final cartItems = cartController.cartItems;
    final subtotal = _calculateSubtotal(cartItems);
    final shippingFee = _calculateShippingFee();
    final tax = _calculateTax(subtotal);
    final total = _calculateTotal(subtotal, shippingFee, tax);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.grey),
                      const SizedBox(height: 16),
                      const Text('Your cart is empty', style: AppTextStyles.heading3),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Continue Shopping'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order summary section
                      _buildSectionHeader('Order Summary'),
                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ...cartItems.map((item) => _buildCartItem(item)),
                              const Divider(),
                              _buildPriceSummary('Subtotal', subtotal),
                              _buildPriceSummary('Shipping', shippingFee),
                              _buildPriceSummary('Tax (5%)', tax),
                              const Divider(),
                              _buildPriceSummary('Total', total, isTotal: true),
                            ],
                          ),
                        ),
                      ),

                      // Shipping address section
                      _buildSectionHeader('Shipping Address'),
                      shippingController.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : shippingController.hasAddresses
                              ? Column(
                                  children: [
                                    ...shippingController.addresses.map((address) =>
                                      _buildAddressCard(address, shippingController)
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const AddShippingAddressScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add New Address'),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            const Icon(
                                              Icons.location_off,
                                              size: 48,
                                              color: AppColors.grey,
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'No shipping addresses found',
                                              style: AppTextStyles.bodyLarge,
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const AddShippingAddressScreen(),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.add),
                                              label: const Text('Add Address'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                      // Place order button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading || shippingController.selectedAddress == null
                              ? null
                              : _placeOrder,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: AppTextStyles.buttonText,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('PLACE ORDER'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.heading3,
      ),
    );
  }

  Widget _buildCartItem(CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported,
                        color: AppColors.grey,
                      ),
                    )
                  : const Icon(
                      Icons.image_not_supported,
                      color: AppColors.grey,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${item.quantity}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),

          // Price
          Text(
            'GHS ${(item.price * item.quantity).toStringAsFixed(2)}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                : AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(ShippingAddressModel address, ShippingController shippingController) {
    final isSelected = shippingController.selectedAddress?.id == address.id;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: InkWell(
          onTap: () {
            shippingController.selectAddress(address.id);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio button
                Radio<String>(
                  value: address.id,
                  groupValue: shippingController.selectedAddress?.id,
                  onChanged: (value) {
                    if (value != null) {
                      shippingController.selectAddress(value);
                    }
                  },
                ),
                const SizedBox(width: 8),

                // Address details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.fullName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (address.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Default',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.phoneNumber,
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.formattedAddress,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
