import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/order_model.dart';
import '../../../utils/utils.dart';
import 'order_details_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      final orderController = Provider.of<OrderController>(context, listen: false);
      orderController.fetchOrders(authController.user!.id);
    });
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
    final orderController = Provider.of<OrderController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: orderController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderController.hasOrders
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orderController.orders.length,
                  itemBuilder: (context, index) {
                    final order = orderController.orders[index];
                    return _buildOrderCard(order);
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.grey),
                      const SizedBox(height: 16),
                      const Text('No orders found', style: AppTextStyles.heading3),
                      const SizedBox(height: 8),
                      const Text(
                        'You haven\'t placed any orders yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Start Shopping'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(orderId: order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    order.formattedDate,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Order status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.statusText,
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Order summary
              Row(
                children: [
                  Text(
                    '${order.totalItems} ${order.totalItems == 1 ? 'item' : 'items'}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    'Total: \$${order.total.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Item preview (show first 2 items)
              if (order.items.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                for (var i = 0; i < order.items.length && i < 2; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Product image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: order.items[i].productImage.isNotEmpty
                                ? Image.network(
                                    order.items[i].productImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.grey,
                                      size: 20,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image_not_supported,
                                    color: AppColors.grey,
                                    size: 20,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Product name and quantity
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.items[i].productName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Qty: ${order.items[i].quantity}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // If there are more items, show "View all" text
                if (order.items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'View all ${order.items.length} items',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
