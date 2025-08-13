import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../utils/utils.dart';
import '../../../widgets/widgets.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  int _totalProducts = 0;
  int _totalCategories = 0;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  double _totalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get products count
      final productsSnapshot = await _firestore.collection(AppConstants.productsCollection).count().get();
      _totalProducts = productsSnapshot.count!;

      // Get categories count
      final categoriesSnapshot = await _firestore.collection(AppConstants.categoriesCollection).count().get();
      _totalCategories = categoriesSnapshot.count!;

      // Get orders count
      final ordersSnapshot = await _firestore.collection(AppConstants.ordersCollection).get();
      _totalOrders = ordersSnapshot.size;

      // Calculate pending orders and revenue
      double revenue = 0;
      int pendingOrders = 0;

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        // Count pending orders
        if (data['status'] == AppConstants.orderPending) {
          pendingOrders++;
        }

        // Calculate total revenue from completed orders
        if (data['status'] == AppConstants.orderCompleted && data['total'] != null) {
          revenue += (data['total'] as num).toDouble();
          print('Found completed order with total: ${data['total']}'); // Debug print
        }
      }

      _pendingOrders = pendingOrders;
      _totalRevenue = revenue;

      print('Total calculated revenue: $_totalRevenue'); // Debug print

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Text(
                      'Welcome, ${user?.fullname ?? 'Admin'}',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s your store overview',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stats Cards
                    _buildStatsGrid(),
                    const SizedBox(height: 24),

                    // Revenue Card
                    _buildRevenueCard(),
                    const SizedBox(height: 24),

                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Products', _totalProducts.toString(), Icons.inventory, AppColors.primary),
        _buildStatCard('Categories', _totalCategories.toString(), Icons.category, Colors.amber),
        _buildStatCard('Total Orders', _totalOrders.toString(), Icons.shopping_cart, Colors.blue),
        _buildStatCard('Pending Orders', _pendingOrders.toString(), Icons.pending_actions, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTextStyles.heading2.copyWith(
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Revenue',
                  style: AppTextStyles.heading3,
                ),
                Icon(
                  Icons.attach_money,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'GHS ${_totalRevenue.toStringAsFixed(2)}',
              style: AppTextStyles.heading1.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('From completed orders'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersList() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection(AppConstants.ordersCollection)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading recent orders'));
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('No recent orders found'),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;
            final status = order['status'] ?? 'unknown';
            final total = order['totalAmount'] != null
                ? '\$${(order['totalAmount'] as num).toStringAsFixed(2)}'
                : 'N/A';
            final date = order['createdAt'] != null
                ? (order['createdAt'] as Timestamp).toDate()
                : DateTime.now();

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
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('Order #${orderId.substring(0, 8)}...'),
                subtitle: Text('${order['items']?.length ?? 0} items • ${date.day}/${date.month}/${date.year}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(total, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to order details
                },
              ),
            );
          },
        );
      },
    );
  }
}
