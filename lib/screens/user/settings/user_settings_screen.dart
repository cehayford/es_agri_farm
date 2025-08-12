import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../utils/utils.dart';
import '../../../widgets/widgets.dart';
import 'edit_profile_screen.dart';
import '../orders/order_history_screen.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile card
            _buildProfileCard(user),

            const SizedBox(height: 24),

            // Account settings - Only keeping edit profile and change password
            _buildSectionHeader('Account Settings'),
            _buildSettingItem(
              icon: Icons.person,
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            _buildSettingItem(
              icon: Icons.lock,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: () {
                _showChangePasswordDialog();
              },
            ),

            const SizedBox(height: 24),

            // Orders - Only keeping order history
            _buildSectionHeader('Orders'),
            _buildSettingItem(
              icon: Icons.shopping_bag,
              title: 'Order History',
              subtitle: 'View your past orders',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showLogoutConfirmation();
                },
                icon: const Icon(Icons.logout),
                label: const Text('LOGOUT'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // App version
            Center(
              child: Text(
                'App Version ${AppConstants.appVersion}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile image
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.lightGrey,
              backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                  ? NetworkImage(user.profilePicture!)
                  : null,
              child: user.profilePicture == null || user.profilePicture!.isEmpty
                  ? const Icon(Icons.person, size: 40, color: AppColors.grey)
                  : null,
            ),
            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullname,
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to edit profile
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('View Profile'),
                  ),
                ],
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

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  CustomTextField(
                    label: 'Current Password',
                    hint: 'Enter your current password',
                    controller: currentPasswordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'New Password',
                    hint: 'Enter your new password',
                    controller: newPasswordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Confirm Password',
                    hint: 'Confirm your new password',
                    controller: confirmPasswordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        // Validate input
                        if (currentPasswordController.text.isEmpty ||
                            newPasswordController.text.isEmpty ||
                            confirmPasswordController.text.isEmpty) {
                          setState(() {
                            errorMessage = 'All fields are required';
                          });
                          return;
                        }

                        if (newPasswordController.text.length < 8) {
                          setState(() {
                            errorMessage = 'New password must be at least 8 characters';
                          });
                          return;
                        }

                        if (newPasswordController.text != confirmPasswordController.text) {
                          setState(() {
                            errorMessage = 'Passwords do not match';
                          });
                          return;
                        }

                        // Update password
                        setState(() {
                          isLoading = true;
                          errorMessage = null;
                        });

                        try {
                          final authController = Provider.of<AuthController>(context, listen: false);
                          await authController.changePassword(
                            currentPassword: currentPasswordController.text,
                            newPassword: newPasswordController.text,
                          );

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                            errorMessage = e.toString();
                          });
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('CHANGE'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    await authController.logout();
    // No need for navigation - the app.dart will handle redirecting to login
  }
}
