import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/order_model.dart';
import '../../../utils/utils.dart';
import '../../../widgets/widgets.dart';
import 'admin_order_details_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<DocumentSnapshot> _orders = [];
  String _statusFilter = 'all'; // 'all', 'pending', 'completed', 'cancelled'

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Query query = _firestore.collection(AppConstants.ordersCollection)
          .orderBy('orderDate', descending: true);

      // Apply status filter if not 'all'
      if (_statusFilter != 'all') {
        query = query.where('status', isEqualTo: _statusFilter);
      }

      final snapshot = await query.get();

      print('Orders fetched: ${snapshot.docs.length}'); // Debug print to check results

      setState(() {
        _orders = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', AppConstants.orderPending),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', AppConstants.orderCompleted),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cancelled', AppConstants.orderCancelled),
                ],
              ),
            ),
          ),

          // Order count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_orders.length} ${_orders.length == 1 ? 'Order' : 'Orders'}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final doc = _orders[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final id = doc.id;

                          return _buildOrderItem(id, data);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
        _fetchOrders();
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Orders Found',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            _statusFilter == 'all'
                ? 'There are no orders yet'
                : 'There are no ${_statusFilter} orders',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String id, Map<String, dynamic> data) {
    // Get customer name from shippingAddress
    final shippingAddress = data['shippingAddress'] as Map<String, dynamic>? ?? {};
    final customerName = shippingAddress['fullName'] ?? 'Unknown Customer';

    // Get items array
    final items = data['items'] as List<dynamic>? ?? [];
    final itemCount = items.length;

    // Get total amount
    final total = data['total'] != null
        ? 'GHS ${(data['total'] as num).toStringAsFixed(2)}'
        : 'N/A';

    // Get status
    final status = data['status'] ?? 'unknown';

    // Get order date
    final orderDate = data['orderDate'] != null
        ? (data['orderDate'] as Timestamp).toDate()
        : DateTime.now();

    // Format date
    final formattedDate = '${orderDate.day}/${orderDate.month}/${orderDate.year}';
    final formattedTime = '${orderDate.hour}:${orderDate.minute.toString().padLeft(2, '0')}';

    // Get color based on status
    Color statusColor;
    switch (status) {
      case AppConstants.orderPending:
        statusColor = AppColors.warning;
        break;
      case AppConstants.orderCompleted:
        statusColor = AppColors.success;
        break;
      case AppConstants.orderCancelled:
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Order ID
                Text(
                  'Order #${id.substring(0, 8)}...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Order details
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(customerName),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('$formattedDate at $formattedTime'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('$itemCount ${itemCount == 1 ? 'item' : 'items'}'),
              ],
            ),

            const Divider(height: 24),

            // Order summary and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Total amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Amount'),
                    Text(
                      total,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                // Action buttons
                Row(
                  children: [
                    // View details button
                    ElevatedButton.icon(
                      onPressed: () {
                        _showOrderDetails(id, data);
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Update status button (only for pending orders)
                    if (status == AppConstants.orderPending)
                      ElevatedButton.icon(
                        onPressed: () {
                          _showStatusUpdateDialog(id, status);
                        },
                        icon: const Icon(Icons.update),
                        label: const Text('Update'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOrderDetails(String id, Map<String, dynamic> data) async {
    // Extract data from the order
    final items = data['items'] as List<dynamic>? ?? [];
    final shippingAddress = data['shippingAddress'] as Map<String, dynamic>? ?? {};

    // Customer information from shipping address
    final customerName = shippingAddress['fullName'] ?? 'Unknown Customer';
    final phoneNumber = shippingAddress['phoneNumber'] ?? 'No phone number';

    // Format address
    final addressParts = [
      shippingAddress['addressLine1'],
      shippingAddress['addressLine2'],
      shippingAddress['city'],
      shippingAddress['state'],
      shippingAddress['postalCode']
    ].where((part) => part != null && part.toString().isNotEmpty).join(', ');
    final address = addressParts.isNotEmpty ? addressParts : 'No address provided';

    // Order details
    final status = data['status'] ?? 'unknown';
    final total = data['total'] != null
        ? 'GHS ${(data['total'] as num).toStringAsFixed(2)}'
        : 'N/A';

    // Order date
    final orderDate = data['orderDate'] != null
        ? (data['orderDate'] as Timestamp).toDate()
        : DateTime.now();
    final formattedDate = '${orderDate.day}/${orderDate.month}/${orderDate.year} at ${orderDate.hour}:${orderDate.minute.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Details',
                        style: AppTextStyles.heading2,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Order ID and date
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${id.substring(0, 8)}...',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Placed on $formattedDate'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Customer info
                  Text(
                    'Customer Information',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Name', customerName),
                  _buildInfoRow('Phone', phoneNumber),
                  _buildInfoRow('Address', address),
                  const SizedBox(height: 24),

                  // Order items
                  Text(
                    'Order Items',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = items[index] as Map<String, dynamic>;
                      final productName = item['productName'] ?? 'Unknown Product';
                      final productPrice = item['price'] != null
                          ? 'GHS ${(item['price'] as num).toStringAsFixed(2)}'
                          : 'N/A';
                      final quantity = item['quantity'] ?? 1;
                      final subtotal = (item['price'] != null && item['quantity'] != null)
                          ? 'GHS ${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)}'
                          : 'N/A';

                      return Row(
                        children: [
                          // Product image or placeholder
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: item['productImage'] != null && (item['productImage'] as String).isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['productImage'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.image_not_supported);
                                      },
                                    ),
                                  )
                                : const Icon(Icons.inventory_2_outlined),
                          ),
                          const SizedBox(width: 12),
                          // Product details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('$productPrice x $quantity'),
                              ],
                            ),
                          ),
                          // Subtotal
                          Text(
                            subtotal,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    },
                  ),

                  const Divider(height: 32),

                  // Order summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount'),
                      Text(
                        total,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  if (status == AppConstants.orderPending)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateOrderStatus(id, AppConstants.orderCompleted);
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Mark as Completed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateOrderStatus(id, AppConstants.orderCancelled);
                            },
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel Order'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusUpdateDialog(String id, String currentStatus) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status options
            ListTile(
              title: const Text('Mark as Completed'),
              leading: const Icon(Icons.check_circle, color: AppColors.success),
              onTap: () {
                Navigator.pop(context);
                _updateOrderStatus(id, AppConstants.orderCompleted);
              },
            ),
            ListTile(
              title: const Text('Cancel Order'),
              leading: const Icon(Icons.cancel, color: AppColors.error),
              onTap: () {
                Navigator.pop(context);
                _updateOrderStatus(id, AppConstants.orderCancelled);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String id, String newStatus) async {
    try {
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(id)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${newStatus == AppConstants.orderCompleted ? 'completed' : 'cancelled'} successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Refresh the orders list
      _fetchOrders();
    } catch (e) {
      print('Error updating order status: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.orderPending:
        return AppColors.warning;
      case AppConstants.orderCompleted:
        return AppColors.success;
      case AppConstants.orderCancelled:
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }
}
