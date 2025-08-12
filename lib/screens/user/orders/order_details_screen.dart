import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/order_model.dart';
import '../../../utils/utils.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isLoading = true;
  OrderModel? _order;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  // Load order details
  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final orderController = Provider.of<OrderController>(context, listen: false);
      final order = await orderController.getOrderDetails(widget.orderId);

      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load order details: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Cancel order
  Future<void> _cancelOrder() async {
    if (_order == null) return;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orderController = Provider.of<OrderController>(context, listen: false);
      final authController = Provider.of<AuthController>(context, listen: false);

      final success = await orderController.cancelOrder(
        widget.orderId,
        authController.user!.id,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: AppColors.success,
            ),
          );

          // Refresh order details
          await _loadOrderDetails();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderController.error),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Get color based on order status
  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.orderPending:
      case 'processing':
        return AppColors.warning;
      case AppConstants.orderCompleted:
      case 'delivered':
        return AppColors.success;
      case AppConstants.orderCancelled:
        return AppColors.error;
      case 'shipped':
        return Colors.blue;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_error, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadOrderDetails,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _order == null
                  ? const Center(child: Text('Order not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order ID and status
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Order ID',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '#${_order!.id.substring(0, 8)}',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Date',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _order!.formattedDate,
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Order Status',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(_order!.status)
                                                  .withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              _order!.statusText,
                                              style: TextStyle(
                                                color: _getStatusColor(_order!.status),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_order!.status == AppConstants.orderPending)
                                        TextButton.icon(
                                          onPressed: _cancelOrder,
                                          icon: const Icon(Icons.cancel, color: AppColors.error),
                                          label: const Text(
                                            'Cancel Order',
                                            style: TextStyle(color: AppColors.error),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Order items
                          _buildSectionHeader('Order Items'),
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  ..._order!.items.map((item) => _buildOrderItem(item)),
                                  const Divider(),
                                  _buildPriceRow('Subtotal', _order!.subtotal),
                                  _buildPriceRow('Shipping', _order!.shippingFee),
                                  _buildPriceRow('Tax', _order!.tax),
                                  const SizedBox(height: 8),
                                  _buildPriceRow('Total', _order!.total, isTotal: true),
                                ],
                              ),
                            ),
                          ),

                          // Shipping address
                          _buildSectionHeader('Shipping Address'),
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _order!.shippingAddress['fullName'] ?? '',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _order!.shippingAddress['phoneNumber'] ?? '',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatAddress(_order!.shippingAddress),
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Payment method
                          _buildSectionHeader('Payment Information'),
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.payment, color: AppColors.grey),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Payment Method',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

  Widget _buildOrderItem(OrderItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: item.productImage.isNotEmpty
                  ? Image.network(
                      item.productImage,
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
                  item.productName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.price.toStringAsFixed(2)} × ${item.quantity}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),

          // Item total
          Text(
            '\$${item.totalPrice.toStringAsFixed(2)}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
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
            '\$${amount.toStringAsFixed(2)}',
            style: isTotal
                ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                : AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    String formattedAddress = address['addressLine1'] ?? '';
    if (address['addressLine2'] != null && address['addressLine2'].isNotEmpty) {
      formattedAddress += ', ${address['addressLine2']}';
    }
    formattedAddress += ', ${address['city'] ?? ''}, ${address['state'] ?? ''} ${address['postalCode'] ?? ''}';
    return formattedAddress;
  }
}
