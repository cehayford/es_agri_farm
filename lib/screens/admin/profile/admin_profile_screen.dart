import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../controllers/auth_controller.dart';
import '../../../utils/utils.dart';
import '../../../widgets/widgets.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isChangingPassword = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  void _initializeUserData() {
    final user = Provider.of<AuthController>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.fullname;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error selecting image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    final user = authController.user;

    if (user == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? profilePictureUrl = user.profilePicture;

      // Upload new image if selected
      if (_selectedImage != null) {
        final storageRef = _storage.ref().child('profile_pictures/${user.id}.jpg');
        await storageRef.putFile(_selectedImage!);
        profilePictureUrl = await storageRef.getDownloadURL();
      }

      // Update user document in Firestore
      await _firestore.collection(AppConstants.usersCollection).doc(user.id).update({
        'fullname': _nameController.text.trim(),
        'profilePicture': profilePictureUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user model
      final updatedUser = user.copyWith(
        fullname: _nameController.text.trim(),
        profilePicture: profilePictureUrl,
      );

      // Force refresh the state
      authController.refreshUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
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

  Future<void> _changePassword() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final authController = Provider.of<AuthController>(context, listen: false);

      // Use the AuthController's changePassword method for secure password change
      await authController.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Clear the password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      print('Error changing password: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
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

  Future<void> _showChangePasswordDialog() async {
    // Create temporary controllers just for this dialog to avoid disposal issues
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    // Local state variables
    bool isChanging = false;
    String? errorMessage;
    bool success = false;

    // Use a StatefulBuilder to allow updating the dialog's state
    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success message
                      if (success)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.success),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Password changed successfully!',
                                  style: TextStyle(color: AppColors.success),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Error message
                      if (errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error),
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

                      // Current password field
                      CustomTextField(
                        label: 'Current Password',
                        hint: 'Enter your current password',
                        controller: currentPasswordController,
                        prefixIcon: Icons.lock_outline,
                        enabled: !isChanging && !success,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // New password field
                      CustomTextField(
                        label: 'New Password',
                        hint: 'Enter your new password',
                        controller: newPasswordController,
                        prefixIcon: Icons.lock_outline,
                        enabled: !isChanging && !success,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          } else if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm password field
                      CustomTextField(
                        label: 'Confirm Password',
                        hint: 'Confirm your new password',
                        controller: confirmPasswordController,
                        prefixIcon: Icons.lock_outline,
                        enabled: !isChanging && !success,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password';
                          } else if (value != newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Cancel button
                TextButton(
                  onPressed: isChanging ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),

                // Change Password / Done button
                if (success)
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Done'),
                  )
                else
                  ElevatedButton(
                    onPressed: isChanging ? null : () async {
                      if (formKey.currentState!.validate()) {
                        // Update loading state
                        setState(() {
                          isChanging = true;
                          errorMessage = null;
                        });

                        try {
                          final authController = Provider.of<AuthController>(context, listen: false);

                          // Use the AuthController's changePassword method
                          await authController.changePassword(
                            currentPassword: currentPasswordController.text.trim(),
                            newPassword: newPasswordController.text.trim(),
                          );

                          // Update success state
                          setState(() {
                            isChanging = false;
                            success = true;
                          });

                          // Show success snackbar
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error changing password: $e');

                          // Extract a more user-friendly error message
                          String friendlyMessage = 'Failed to change password';

                          if (e.toString().contains('wrong-password') ||
                              e.toString().contains('incorrect') ||
                              e.toString().contains('auth credential is incorrect')) {
                            friendlyMessage = 'The current password you entered is incorrect';
                          } else if (e.toString().contains('requires-recent-login') ||
                                     e.toString().contains('expired')) {
                            friendlyMessage = 'Your session has expired. Please log out and log in again before changing your password';
                          } else if (e.toString().contains('weak-password')) {
                            friendlyMessage = 'Your new password is too weak. Please use a stronger password';
                          }

                          // Update error state
                          setState(() {
                            isChanging = false;
                            errorMessage = friendlyMessage;
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: isChanging
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : const Text('Change Password'),
                  ),
              ],
            );
          }
        );
      },
    ).then((_) {
      // Properly dispose of the controllers when the dialog is closed
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

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
        title: const Text('Admin Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  // Profile image
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: AppColors.lightGrey,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : (user.profilePicture != null && user.profilePicture!.isNotEmpty
                        ? NetworkImage(user.profilePicture!)
                        : null),
                    child: (user.profilePicture == null || user.profilePicture!.isEmpty) && _selectedImage == null
                        ? const Icon(Icons.person, size: 64, color: AppColors.grey)
                        : null,
                  ),

                  // Edit button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Email display
            Text(
              user.email,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            // Role badge
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Profile Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 16),

                  // Name field
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Update Profile',
                      onPressed: _updateProfile,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Account Settings
            const Text(
              'Account Settings',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),

            // Change Password Button
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: AppColors.primary),
              ),
              title: const Text('Change Password'),
              subtitle: const Text('Update your password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showChangePasswordDialog();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.grey.withOpacity(0.3)),
              ),
            ),
            const SizedBox(height: 12),

            // Logout Button
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: AppColors.error),
              ),
              title: const Text('Logout'),
              subtitle: const Text('Sign out from your account'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showLogoutConfirmation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.grey.withOpacity(0.3)),
              ),
            ),

            const SizedBox(height: 32),

            // App Info
            Text(
              'App Version ${AppConstants.appVersion}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
