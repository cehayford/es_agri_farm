import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../controllers/order_controller.dart';
import '../../../models/order_model.dart';
import '../../../utils/utils.dart';
import '../../../widgets/widgets.dart';

class AdminOrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<AdminOrderDetailsScreen> createState() => _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  bool _isLoading = true;
  OrderModel? _order;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(widget.orderId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _order = OrderModel.fromSnapshot(docSnapshot);
          _isLoading = false;
        });
      } else {
        _showErrorAndNavigateBack('Order not found');
      }
    } catch (e) {
      _showErrorAndNavigateBack('Error loading order details: $e');
    }
  }

  void _showErrorAndNavigateBack(String message) {
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update the order status in Firestore
      await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(widget.orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh the order details
      await _fetchOrderDetails();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${_getStatusText(newStatus)}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

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

  String _getStatusText(String status) {
    switch (status) {
      case AppConstants.orderPending:
        return 'Pending';
      case AppConstants.orderCompleted:
        return 'Completed';
      case AppConstants.orderCancelled:
        return 'Cancelled';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.orderPending:
        return AppColors.warning;
      case AppConstants.orderCompleted:
      case 'delivered':
        return AppColors.success;
      case AppConstants.orderCancelled:
        return AppColors.error;
      case 'processing':
      case 'shipped':
        return AppColors.info;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId.substring(0, 8)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrderDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : _buildOrderDetails(),
    );
  }

  Widget _buildOrderDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order status card
          _buildStatusCard(),
          const SizedBox(height: 24),

          // Customer information
          _buildSectionTitle('Customer Information'),
          _buildCustomerInfo(),
          const SizedBox(height: 24),

          // Shipping Address
          _buildSectionTitle('Shipping Address'),
          _buildShippingAddress(),
          const SizedBox(height: 24),

          // Order items
          _buildSectionTitle('Order Items (${_order!.items.length})'),
          _buildOrderItems(),
          const SizedBox(height: 24),

          // Order summary
          _buildSectionTitle('Order Summary'),
          _buildOrderSummary(),
          const SizedBox(height: 32),

          // Action buttons
          if (_order!.status == AppConstants.orderPending)
            _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(_order!.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${widget.orderId.substring(0, 8)}...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_order!.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _order!.statusText.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(_order!.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Placed on ${_order!.formattedDate}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '${_order!.totalItems} ${_order!.totalItems == 1 ? 'item' : 'items'}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.heading3,
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Full Name',
              value: _order!.shippingAddress['fullName'] ?? 'Not provided',
            ),
            const Divider(height: 16),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _order!.shippingAddress['email'] ?? 'Not provided',
            ),
            const Divider(height: 16),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _order!.shippingAddress['phone'] ?? 'Not provided',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingAddress() {
    final address = _order!.shippingAddress;
    final formattedAddress = [
      address['street'] ?? '',
      address['city'] ?? '',
      address['state'] ?? '',
      address['zipCode'] ?? '',
      address['country'] ?? '',
    ].where((element) => element.isNotEmpty).join(', ');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildInfoRow(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: formattedAddress.isNotEmpty ? formattedAddress : 'No address provided',
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _order!.items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _order!.items[index];
          return Padding(
            padding: const EdgeInsets.all(16),
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
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, size: 30),
                          )
                        : Container(
                            color: AppColors.lightGrey,
                            child: const Icon(Icons.inventory_2_outlined, size: 30),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${item.price.toStringAsFixed(2)} x ${item.quantity}',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Total price
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', _order!.subtotal),
            const SizedBox(height: 8),
            _buildPriceRow('Shipping', _order!.shippingFee),
            const SizedBox(height: 8),
            _buildPriceRow('Tax', _order!.tax),
            const Divider(height: 24),
            _buildPriceRow(
              'Total',
              _order!.total,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showStatusUpdateDialog(),
          icon: const Icon(Icons.edit),
          label: const Text('UPDATE STATUS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _updateOrderStatus(AppConstants.orderCancelled),
          icon: const Icon(Icons.cancel, color: AppColors.error),
          label: const Text('CANCEL ORDER'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _showStatusUpdateDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('Processing', 'processing', Icons.sync, AppColors.info),
            _buildStatusOption('Shipped', 'shipped', Icons.local_shipping, AppColors.info),
            _buildStatusOption('Delivered', 'delivered', Icons.check_circle, AppColors.success),
            _buildStatusOption('Completed', AppConstants.orderCompleted, Icons.done_all, AppColors.success),
            _buildStatusOption('Cancelled', AppConstants.orderCancelled, Icons.cancel, AppColors.error),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String label, String status, IconData icon, Color color) {
    return ListTile(
      title: Text(label),
      leading: Icon(icon, color: color),
      onTap: () {
        Navigator.pop(context);
        _updateOrderStatus(status);
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}
