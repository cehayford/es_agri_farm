import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../utils/utils.dart';
import '../../../widgets/widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authController.logout();
              // No need to navigate - app.dart will handle this
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${authController.user?.fullname ?? 'Admin'}',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 24),

              // Admin Dashboard Content
              const Text(
                'This is the admin dashboard. From here you can manage products, orders, and users.',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),

              // Grid of actions
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                children: [
                  _buildActionCard(
                    context,
                    title: 'Manage Products',
                    icon: Icons.inventory,
                    color: AppColors.primary,
                    onTap: () {
                      // Navigate to product management screen
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'View Orders',
                    icon: Icons.shopping_cart,
                    color: AppColors.accent,
                    onTap: () {
                      // Navigate to orders screen
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'Manage Users',
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () {
                      // Navigate to user management screen
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'Analytics',
                    icon: Icons.bar_chart,
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to analytics screen
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
